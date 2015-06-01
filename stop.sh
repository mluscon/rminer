#!/bin/bash

cat ./web.pid > kill

ruby -I ./ ./daemon.rb stop
