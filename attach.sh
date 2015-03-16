#!/bin/bash

NODE=${1:-"box3"}
erl -remsh $NODE@`hostname -s` -s king attach -sname `mkpasswd -c 0 -s 0` -cookie synrc_cookie
