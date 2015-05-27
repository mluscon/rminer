#!/bin/ruby

require 'rubygems'
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

user = User.new()
user.username = ARGV[0]
user.password = ARGV[1]
user.save
