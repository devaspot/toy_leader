#!/bin/bash

kill -9 `ps aux | grep synrc_cookie | awk '{print $2}'`
