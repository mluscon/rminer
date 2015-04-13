#!/bin/ruby

require 'rubygems'
require 'amqp'
require 'parseconfig'
require 'digest/murmurhash'

require './redis_worker'
require './filters.rb'

#config
config = ParseConfig.new('./rminer.conf')
amqp_server = config['amqp_server']
workers = config['workers'].to_i
channel = config['channel']
cache_size = config['cache'].to_i
children = []
filter_fact = FilterMaker.new
filters = filter_fact.update_filters

workers.times do
  pid = fork do
    redis = RedisWorker.new
    redis.run!
  end
  puts 'Started analyzator process with pid ' + pid.to_s + '.'
  children.push pid
end

Thread.new do
  puts 'Started filter thread.'
  redis = Redis.new
  while true
    if update = redis.rpop('filter')
      puts 'Updating filters'
      filters = filter_fact.update_filters
      filter_fact.remove_msgs
    end
    sleep(2)
  end
end

AMQP.start( :host => amqp_server ) do |connection|
  channel = AMQP::Channel.new( connection )
  queue = channel.queue('test', :auto_delete => true)
  i = 0
  msgs = []
  queue.subscribe do |metadata, payload|
    if filters.empty?
      msgs.push( payload )
    else
      filters.each do |filter|
        if filter.match(payload)
          break
        end
        if filter == filters[-1]
          msgs.push( payload )
        end
      end
    end

    if msgs.length == cache
      msgs.each do |msg|
        Message.create(
                       :body => msg,
                       :body_hash => Digest::Digest::MurmurHash3_x64_128.hexdigest(msg).to_s
                      )
      end
      msgs = []
    end
  end
end



