require 'data_mapper'
require 'redis'

require './models/model.rb'

class WebController
  
  def initialize
    @database = DataMapper.setup :default, {
      :adapter  => 'postgres',
      :host     => 'localhost',
      :database => 'thesis',
      :user     => 'gproject',
      :password => 'gproject'
    }
    @redis = Redis.new
    #find a proper place
    DataMapper.finalize
    DataMapper.auto_upgrade!
  end

  
  def count
    Message.all(:analyzed => false).count 
  end
  
  def pattern(id)
    pattern = Pattern.get(id.to_i)
  end
  
  def analyze(sensitivity,pattern_id=nil)
    
    unless pattern_id.nil?
      pattern = Pattern.get pattern_id.to_i
      msgs = pattern.scan.messages.all
    else
      msgs = Message.all
    end
 
    new_scan = Scan.create
    
    msgs.each do |msg|
      msg.scans << new_scan
      msg.save
    end
    
    @redis.rpush( "scans", new_scan.id )   
      
  end
  
  def scan(id)
    scan = Scan.get id.to_i
  end

  
end