require 'redis'
require 'data_mapper'

require './canon.rb'
require './models/model.rb'


class RedisWorker

  def initialize(algorithms, config)
    @database = DataMapper.setup :default, {
      :adapter  => config.adapter,
      :host     => config.host,
      :database => config.database,
      :user     => config.user,
      :password => config.password,
    }
    @redis = Redis.new
    DataMapper.finalize
    @algorithms = algorithms
  end

  def run!
    while true
      if scan = @redis.rpop('scans')
        $logger.info("Processing scan id #{scan}")
        do_analyze scan
      else
        sleep 3
      end
    end
  end

  def rerun
    Scan.all(:active=>true).each do |scan|
      $logger.info("Restarted analysis of scan id #{scan.id}")
      scan.patterns.each do |pattern|
        assocs = MessagePattern.all(:pattern=>pattern)
        assocs.each do |asc|
          assocs.destroy!
        end
        pattern.destroy!
      end
      do_analyze(scan.id)
    end
  end

  def do_analyze(scan_id)

    scan = Scan.get(scan_id)
    sep = Regexp.new scan.separator
    alg = scan.algorithm

    raw_patterns = nil
    @algorithms.each do |algorithm|
      if algorithm.class.to_s == alg
        msgs = scan.messages.map{|msg| msg.body}
        raw_patterns = algorithm.run(msgs, scan.sensitivity, sep)
        break;
      end
    end

    if not raw_patterns
      $logger.error("No patterns found.")
      return
    end

    canon_patterns = canonize(raw_patterns, scan.messages, sep)

    canon_patterns.keys.each do |pattern|
      db_pattern = Pattern.new(:body => pattern)
      db_pattern.save
      scan.patterns << db_pattern
    end

    scan.messages.each do |msg|
      scan.patterns.each do |pattern|
        pattern.body.split.each_with_index do |word, pos|
          if msg.body.split[pos] == word
            msg.patterns << pattern
          end
        end
      end
    end

    scan.active = false
    scan.save!
    $logger.info("Scan #{scan_id} finished.")
  end

end