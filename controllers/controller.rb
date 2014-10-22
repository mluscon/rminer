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
  
  def remove(msg_ids)
    if msg_ids.length == 0
      STDERR.puts "Error: empty remove call."
      return
    end
    
    msgs = []
    msg_ids.each do |id|
      msg = Message.get(id)
      if (msg)
        msg.destroy
      end
    end
  end
  
  def pattern(id)
    pattern = Pattern.get(id.to_i)
  end
  
  def final(id)
    pattern = Pattern.get(id.to_i)
    pattern.final = true;
    pattern.save
  end
  
  def analyze(sens ,msg_ids, separator, tag = "")
    
    if msg_ids.length == 0
      STDERR.puts "Error: empty analyze call."
      return
    end
    
    if separator.nil? or separator.empty?
      separator = '\s'
    end
    
    msgs = []
    msg_ids.each do |id|
      msg = Message.get(id)
      if (msg)
        msgs << msg
      else
        puts "nil"      
      end
    end
  
    new_scan = Scan.new
    new_scan.separator = separator
    new_scan.tag = tag
    new_scan.sensitivity = sens
    new_scan.save
    
    msgs.each do |msg|
      msg.scans << new_scan
      msg.analyzed = true
      msg.save
    end
    
    @redis.rpush('scans', new_scan.id )   
      
  end
  
  def scans_serial(active=false)
    scans = []
    Scan.all(:active => active).each do |scan|
      #dirty dirty hack
      scans.push JSON.parse( scan.to_json(:methods=>[:patterns]) )
    end
     scans
  end
  
  def scans(active=false)
    Scan.all(:active => active)
  end
  
  def scan_hide(id)
    scan = Scan.get(id)
    scan.hidden ? scan.hidden = false : scan.hidden = true 
    scan.save
  end
  
end