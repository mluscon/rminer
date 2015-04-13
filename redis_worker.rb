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

    DataMapper.finalize
  end

  def run!
    while true
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
    separator = Regexp.new scan.separator

    patterns = analyze(scan.sensitivity, scan.messages, separator )

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