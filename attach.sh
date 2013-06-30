#!/bin/bash

NODE=${1:-"box3"}
erl -remsh $NODE@`hostname -s` -s king attach -sname `makepasswd --char=4` -cookie synrc_cookie
