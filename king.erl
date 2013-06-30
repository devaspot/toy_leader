-module(king).
-author('Namdak Tonpa').
-compile(export_all).
-record(state,{king,no,self}).
-define(T, 100).
-define(N, 4).

% Protocol here is as simple as its desctiption.
% Here we divided the server into two parts as described in
% specification: Heartbeat and Server.
% Heartbeat. If leader is unavailable we need to elect.

heartbeat(State) ->
    ping(State#state.king),
    H = receive
        {'PONG',_,_,_,_} -> timer:sleep(?T*8), State;
        {'CHANGE',Node,No} -> State#state{king=Node,no=No};
        M -> send("sh",{print,io_lib:format("~nUnknown Heart Message: ~p~n",[M])}), State
    after ?T * 4 -> elect(), State end,
    heartbeat(H).

% Server. Server only do the elections and notification.
% We did here little optimization for network traffic.

server(State) ->
%    send("sh",{print,"."}),
    S = receive
        {'ELECT'} -> spawn(fun() -> election() end), State;
        {'MAJOR',Res} -> case Res of no -> king(State); yes -> State end;
        {'ALIVE?',Box} -> fine(Box,State);
        {'KING',Node,No} -> change(State,Node,No);
        {'PING',Box} -> pong(Box,State);
        {'FINE',Node,No,King} -> State#state{king=King};
        {'REG',K,V} -> reg(K,V), State;
        {'DEBUG'} -> spawn(fun() -> debug() end), State;
        {'INFO'} -> spawn(fun() -> info() end), State;
        M -> send("sh",{print,io_lib:format("~nUnknown Server Message: ~p~n",[M])}), State
    end, server(S).

% Here is simple firestarter. We join all nodes into Erlang cluster during start.
% And spawn two toy_servers and register them in cluster with global.

start() -> [ net_adm:ping(Box) || Box <- boxes(?N) ], {No,_} = current(),
    Pid = spawn(fun() -> server(#state{no=No,self=self()}) end),
    Mon = spawn(fun() -> heartbeat(#state{no=0}) end),
    Pid ! {'REG',node(),Pid},
    Pid ! {'REG',{node(),beat},Mon}.

% We should ensure all majors alive thus we will wait
% for at least one message (only in case we are not #1).
% This collector placed outside main loop and spawned in
% separate proc just as debug info.

fine(Box,State) -> Box ! {'FINE',node(),State#state.no,State#state.king}, State.
elect() -> send(node(),{'ELECT'}).
election() -> 
    L = [ send(Box,{'ALIVE?',self()}) || Box <- majors() ],
    Res = case length(L) > 0 of
        true -> receive {'FINE',_,_,_} -> yes after ?T * 4 -> no end;
        false -> no end,
    send(node(),{'MAJOR',Res}).

% Simple PING/PONG protocol used between Heartbeat and Server procs

ping(Node) -> send(Node,{'PING',Node}).
pong(Node,State) ->
    send({Node,beat},{'PONG',State#state.king,State#state.no,self(),node()}),
    State.

% Change the state to current King. Used only withing Heartbeat proc

change(State,Node,No) ->
    send({node(),beat},{'CHANGE',Node,No}),
    State#state{king=No}.

% Announce the Leader and also notify Heartbeat proc

king(State) ->
    [ send(Box,{'KING',node(),State#state.no}) || Box <- boxes(?N) ],
    change(State,node(),State#state.no).

% Because we using detached erlang nodes and remsh in demo
% we use global subscription to console shell, if you want to
% stream all messages to console just do instead of io:format
%
%        king:send("sh",{print,Message})

attach() -> spawn(fun() -> global:register_name("sh",self()), console() end).
console() -> receive {print,Message} -> io:format(Message);
                     X -> io:format("Console: ~p~n",[X]) end, console().

% Here is global name registry generously provided by OTP
% however we sould bound to it with care.

pid(Name) -> global:whereis_name(Name).
reg(Name,Pid) -> global:re_register_name(Name,Pid).
send(Name,Message) ->
    case global:whereis_name(Name) of 
        undefined -> skip;
        _Pid -> global:send(Name,Message) end.

% Debug prints list. Use it as follow 
% because its designed for "sh" process:
%
%        king:send(node(),info) -> shows server and heartbeat pids of all cluster
%        king:send(node(),debug) -> ping all nodes and show alives

debug() -> [ send(Box,{'ALIVE?',self()}) || Box <- boxes(?N) ],
    Lives = [ receive {'FINE',Node,No,King} -> {Node,No,King,ok}; _ -> '?'
              after ?T * 4 -> dead end || _ <- boxes(?N) ],
    send("sh",{print,io_lib:format("~n~p reduce:~n~p~n",[node(),Lives])}).

info() -> [ send("sh",{print,io_lib:format("node ~p server ~p beat ~p ~n",
            [ Box, pid(Box), pid({Box,beat}) ] )}) || Box <- boxes(?N) ].

% Supplementary minor stuff

boxes(Num) ->
    [ list_to_atom("box" ++ integer_to_list(Box) ++ "@" ++ host()) ||
      Box <- lists:seq(1,Num) ].

current() ->
    [Name,Domain] = string:tokens(atom_to_list(node()),"@"),
    "box" ++ P = Name,
    {list_to_integer(P),Domain}.

majors() ->
    {Box,Host} = current(),
    [ list_to_atom("box" ++ integer_to_list(N) ++ "@" ++ Host) ||
      N <- lists:seq(1,Box-1) ].

host() -> hd(string:tokens(os:cmd("hostname -s"),"\n")).
