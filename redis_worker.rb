require 'redis'
require 'data_mapper'

require './models/model.rb'
require './analysis.rb'

class RedisWorker
  
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
  
  def run!
    while true
    #fork do
      if scan = @redis.rpop('scans')
       puts "Processing scan id #{scan}"
        do_analyze scan
      else
        sleep 3
      end
    end
  end
  
  def do_analyze(scan_id)
    
    scan = Scan.get(scan_id)
    patterns = analyze(scan.sensitivity, scan.messages)
    
    patterns.keys.each do | pattern |
      db_pattern = Pattern.new( :body => pattern )
      db_pattern.save
      scan.patterns << db_pattern
      
      patterns[pattern].each do |msg|
        db_msg = Message.get(msg)
        db_msg.patterns << db_pattern
        db_msg.save
      end
    end
    
    scan.active = false
    scan.save
    puts "Scan #{scan_id} finished."
  end  
  
end