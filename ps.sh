#!/bin/bash

ps aux | grep synrc_cookie | awk "{print $2;}"

