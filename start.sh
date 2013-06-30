#!/bin/bash

NODE=${1:-"box4"}
erl -s king -detached -sname $NODE -cookie synrc_cookie
