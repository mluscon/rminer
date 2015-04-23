require 'data_mapper'
require 'json'

require './models/model.rb'

class FilterMaker

  def initialize(host, database, user, passwd, adapter)
    @database = DataMapper.setup :default, {
      :adapter  => adapter,
      :host     => host,
      :database => database,
      :user     => user,
      :password => passwd,
    }
    DataMapper.finalize
    DataMapper.auto_upgrade!
    @filters = []
  end

  def update_filters
    finalized_patterns = Pattern.all(:active_filter => true)
    @filters = finalized_patterns.map do |pattern|
      body_split = JSON.parse(pattern.body_split)
      msg = body_split.map { |entry| entry["word"] }.join(" ")
      Regexp.new('^' + msg + '$')
    end
    @filters
  end

  def remove_msgs
    @filters.each do |filter|
      puts "Filtering by: " + filter.source
      Message.all.each do |msg|
        if filter.match(msg.body)
          assocs = MessagePattern.all(:message=>msg)
          assocs.each {|asc| asc.destroy!}
          assocs = MessageScan.all(:message=>msg)
          assocs.each {|asc| asc.destroy!}
          msg.destroy!
        end
      end
    end
  end
end
