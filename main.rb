#!/bin/ruby

require 'rubygems'
require 'amqp'
require 'parseconfig'
require 'digest/murmurhash'

require './redis_worker'
require './filters.rb'

#parse config
config = ParseConfig.new('./rminer.conf')
amqp_server = config['amqp_server']
amqp_channel = config['amqp_channel']
workers = config['workers'].to_i
cache_size = config['cache'].to_i

host = config['db_host']
database = config['db_database']
user = config['db_user']
password = config['db_password']
adapter = config['db_adapter']

children = []
filter_fact = FilterMaker.new(host, database, user, password, adapter)
filters = filter_fact.update_filters

algorithms = []
Dir[File.dirname(__FILE__) + '/plugins/*.rb'].each do |file|
  file_reg = Regexp.new "(?<=/)[a-zA-Z0-9_]+(?=.rb)"
  if name = file_reg.match(file)
    require file
    algorithms.push name.to_s.split('_').collect(&:capitalize).join
  end
end

algorithms.map!{|name| Object::const_get(name).new}


workers.times do |index|
  pid = fork do
    redis = RedisWorker.new(host, database, user, password, adapter, algorithms)
    redis.rerun if index == 0
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

EventMachine.run do
  AMQP.connect( :host => amqp_server ) do |connection|
    channel = AMQP::Channel.new(connection)
    queue = channel.queue(amqp_channel, :auto_delete => true)
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
      if msgs.length == cache_size
        msgs.each do |msg|
          Message.create(
                        :body => msg,
                        :body_hash => Digest::MurmurHash3_x64_128.hexdigest(msg).to_s
                        )
        end
        msgs = []
      end
    end
  end
end



