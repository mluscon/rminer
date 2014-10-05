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
  
  def analyze(sens ,msg_ids)
    
    msgs = []
    msg_ids.each do |id|
      msgs << Message.get(id)
    end
  
    new_scan = Scan.new
    new_scan.sensitivity = sens
    new_scan.save
    
    msgs.each do |msg|
      msg.scans << new_scan
      msg.analyzed = true
      msg.save
    end
    
    @redis.rpush('scans', new_scan.id )   
      
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