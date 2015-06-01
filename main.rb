#!/bin/ruby

puts $LOAD_PATH

require 'rubygems'
require 'amqp'
require 'logger'
require 'parseconfig'
require 'digest/murmurhash'

require 'config.rb'
require 'redis_worker.rb'
require 'filters.rb'

# initialize config
conf = RminerConf.new

# setup logging
$logger = Logger.new(conf.logfile)
$logger.level = Logger::DEBUG
$logger.info("===Starting Rminer system...===")

filter_fact = FilterMaker.new(conf.host, conf.database, conf.user, conf.password, conf.adapter)
filters = filter_fact.update_filters

# import plugins
algorithms = []
Dir[File.dirname(__FILE__) + '/plugins/*.rb'].each do |file|
  file_reg = Regexp.new "(?<=/)[a-zA-Z0-9_]+(?=.rb)"
  if name = file_reg.match(file)
    $logger.info("Found plugin file: #{file}.")
    require file
    algorithms.push name.to_s.split('_').collect(&:capitalize).join
  end
end

algorithms.map!{|name| Object::const_get(name).new}

# fork workers
children = []
conf.workers.times do |index|
  pid = fork do
    redis = RedisWorker.new(algorithms, conf)
    redis.rerun if index == 0
    redis.run!
  end
  $logger.info('Started analyzator process with pid ' + pid.to_s + '.')
  children.push pid
end

Thread.new do
  $logger.info("Started filtering thread.")
  redis = Redis.new
  while true
    if update = redis.rpop('filter')
      $logger.info("Updating filters")
      filters = filter_fact.update_filters
      filter_fact.remove_msgs
    end
    sleep(2)
  end
end

# receiver loop
EventMachine.run do
  AMQP.connect( :host => conf.amqp_server ) do |connection|
    channel = AMQP::Channel.new(connection)
    queue = channel.queue(conf.amqp_channel, :auto_delete => true)
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
      if msgs.length == conf.cache_size
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



