Games of Thrones
================

Here is toy leader election for Erlang. It is started as
an solution for Echo interview program. Simple Leader Election
protocol description close to original task:

Leader Election in Distributed Systems with Crash failure
---------------------------------------------------------

When a process is started, it first checks whether a process with
higher priority is active. If such a process exist, the process
simply waits for one of those processes to become the leader.
If, on the other hand, the present process is the process with
highest priority, the process itself tries to become the leader.
Becoming the leader is done by making sure that all processes
with lower priority either are aware of its existence or are
inactive. When all processes with lower priority are informed,
the process announces itself as the leader. Periodically, the
elected leader polls the inactive processes, if one of the
inactive processes is activated, the election process is
restarted. Processes supervise each other with failure
detectors.

Our approach was to show algorithm details as clear as possible.
However we use some tricks like global registering and cluster autojoining.

Compilation
-----------

You need just Erlang. Do in working directory:

    $ ercl king.erl

How to use
----------

To create cluster {1..450} nodes just run

    $ ./startall.sh

To show pids of running processes

    $ ./ps.sh

To kill ones server

    $ ./kill.sh box1

To attach for instance to server #4

    $ ./attach box4
    Erlang R16B (erts-5.10.1) [source] [64-bit] [smp:4:4] [async-threads:10] [kernel-poll:false]
    Eshell V5.10.1  (abort with ^G)
    (box3@rigdzin)1> king:send(node(),{'DEBUG'}).
    <0.53.0>
    (box3@rigdzin)2> box3@rigdzin reduce:
    [{box3@rigdzin,3,2,ok}, {box4@rigdzin,4,2,ok}, {box2@rigdzin,2,2,ok},dead]

Interpretation of king:send(node(),{'DEBUG'}):

    {box4@rigdzin,4,2,ok} -> answer from noe box4@rigdzin #4, current leader #2, status ok

Lets bring box1 back:

    $ ./start box1

And attach to it to ensure #1 leader is back

    $ ./attach box1
    Erlang R16B (erts-5.10.1) [source] [64-bit] [smp:4:4] [async-threads:10] [kernel-poll:false]
    Eshell V5.10.1  (abort with ^G)
    (box1@rigdzin)1> king:send(node(),{'DEBUG'}).
    <0.53.0>
    (box1@rigdzin)2> box3@rigdzin reduce:
    [{box3@rigdzin,3,1,ok}, {box4@rigdzin,4,1,ok}, {box2@rigdzin,2,1,ok}, {box1@rigdzin,4,1,ok}]

To cleanup all nodes just run:

    $ ./killall.sh

Credits
-------

* Maxim Sokhatsky

OM A HUM
