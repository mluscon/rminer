require 'rubygems'
require 'amqp'
require 'data_mapper'
require 'parseconfig'

require './models/model.rb'

config = ParseConfig.new('./rminer.conf')
amqp_server = config['amqp_server']
amqp_channel = config['amqp_channel']
cache_size = config['cache'].to_i

host = config['db_host']
database = config['db_database']
user = config['db_user']
passwd = config['db_password']
adapter = config['db_adapter']
database = DataMapper.setup :default, {
  :adapter  => adapter,
  :host     => host,
  :database => database,
  :user     => user,
  :password => passwd,
}

DataMapper.finalize

EventMachine.run do
  AMQP.connect( :host => amqp_server ) do |connection|
      channel = AMQP::Channel.new( connection )
      queue = channel.queue(amqp_channel, :auto_delete => true)
      ex = channel.default_exchange

      cache_size.times do
        ex.publish "Testing message !!!", :routing_key => queue.name
      end
      sleep(5)

      msgs = Message.all(:body=>"Testing message !!!")
      if not msgs.empty?
        puts "OK: System passed integration testing."
      else
        puts "ERROR: System did not passed integration testing."
      end
      msgs.each {|msg| msg.destroy!}
      connection.close { EventMachine.stop }
  end
end



