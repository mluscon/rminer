require 'data_mapper'
require 'json'

require './models/model.rb'

class FilterMaker

  def initialize
    @database = DataMapper.setup :default, {
      :adapter  => 'postgres',
      :host     => 'localhost',
      :database => 'thesis',
      :user     => 'gproject',
      :password => 'gproject'
    }
    DataMapper.finalize
    DataMapper.auto_upgrade!
    @filters = []
  end

  def update_filters
    finalized_patterns = Pattern.all(:finalized => true)
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
