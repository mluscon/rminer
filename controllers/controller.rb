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

  
  def waiting
    Message.all(:analyzed => false).count 
  end
  
  def messages
    Message.all(:analyzed => false)
  end
 
  
  def pattern(id)
    pattern = Pattern.get(id.to_i)
  end
  
  def analyze(sensitivity,msg_ids=nil)
    
    unless msg_ids.nil?
      msgs = []
      msg_ids.each do |id|
        msgs << Message.get(id)
      end
    else
      msgs = Message.all
    end
 
    new_scan = Scan.create
    
    msgs.each do |msg|
      msg.scans << new_scan
      msg.save
    end
    
    @redis.rpush('waiting', new_scan.id )   
      
  end
  
  def scans(active=false)
    Scan.all(:active => active)
  end
  
  def scan_count(active=false)
    Scan.all(:active => active).count  
  end
    
  
  def scan(id)
    scan = Scan.get id.to_i
  end

  
end