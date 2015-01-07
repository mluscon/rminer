#!/bin/ruby

require 'rubygems'
require 'amqp'
require 'parseconfig'

require './redis_worker'


#config
config = ParseConfig.new('./rminer.conf')
amqp_server = config['amqp_server']
workers = config['workers'].to_i
channel = config['channel']
cache_size = config['cache'].to_i
children = []

workers.times do
  pid = fork do
    redis = RedisWorker.new
    redis.run!
  end
  children.push pid
end

AMQP.start( :host => amqp_server ) do |connection|
  channel = AMQP::Channel.new( connection )
  queue = channel.queue('test', :auto_delete => true)
  i = 0
  msgs = []
  queue.subscribe do |metadata, payload|
    msgs.push( payload )
    if msgs.length == cache
      msgs.each do |msg|
        Message.create(
                       :body => msg,
                       :body_hash => Digest::MD5.new.digest(msg).to_s[1,10]
                      )
      end
      msgs = []
    end
  end
end



