#!/bin/bash

kill $(cat ./web.pid)


ruby -I ./ ./daemon.rb stop
