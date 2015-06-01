#!/bin/bash

rackup -D -P ./web.pid ./config.ru

ruby -I ./ ./daemon.rb start
