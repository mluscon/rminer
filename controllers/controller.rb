require 'data_mapper'
require 'parseconfig'
require 'redis'
require 'tempfile'

require './models/model.rb'
require './helpers/helper.rb'

class WebController

  def initialize
    config = ParseConfig.new('./rminer.conf')
    host = config['db_host']
    database = config['db_database']
    user = config['db_user']
    passwd = config['db_password']
    adapter = config['db_adapter']
    @database = DataMapper.setup :default, {
      :adapter  => adapter,
      :host     => host,
      :database => database,
      :user     => user,
      :password => passwd,
    }
    @redis = Redis.new
    #find a right place
    DataMapper.finalize
    DataMapper.auto_upgrade!
  end

  def info
    info = {}
    info[:messages] = Message.all.count
    info[:scans_done] = Scan.all(:active=>false).count
    info[:scans_prog] = Scan.all(:active=>true).count
    info[:patterns_finalized] = Pattern.all(:finalized=>true).count
    info[:patterns_active] = Pattern.all(:active_filter=>true).count
    info
  end

  def messages(pattern_id=nil)
    if pattern_id
      Pattern.get(pattern_id).messages
    else
      Message.all
    end
  end

  def analyze(msg_ids, parent_id, algorithm, sensitivity, separator)

    if msg_ids.length == 0
      STDERR.puts "Error: empty analyze call."
      return nil
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
        STDERR.puts "No message with id: " + id.to_s
      end
    end

    new_scan = Scan.new
    new_scan.algorithm = algorithm
    new_scan.separator = separator
    new_scan.sensitivity = sensitivity
    new_scan.parent = Pattern.get(parent_id)
    new_scan.save!

    msgs.each do |msg|
      msg.scans << new_scan
      msg.save
    end

    @redis.rpush('scans', new_scan.id )
    return new_scan
  end

  def scans_serial(active=false)
    scans = []
    Scan.all(:active => active, :removing=>false).each do |scan|
      #dirty dirty hack
      scans.push JSON.parse( scan.to_json(:methods=>[:patterns]) )
    end
     scans
  end

  def scan_remove(id)
    scan = Scan.get(id.to_i)
    scan.removing = true
    scan.save
    patterns = scan.patterns
    patterns.each do |pattern|
      if pattern.children
        patterns.children.each do |child_scan|
          scan_remove(child_scan.id)
        end
      end
      assocs = MessagePattern.all(:pattern=>pattern)
      assocs.each do |asc|
        asc.destroy!
      end
      pattern.destroy!
    end
    assocs = MessageScan.all(:scan=>scan)
    assocs.each do |asc|
      asc.destroy!
    end
    scan.destroy!
  end

  def scan_finalize(id)
    scan = Scan.get(id.to_i)
    return false if not scan
    scan.removing = true
    scan.save
    scan.patterns.each do |pattern|
      pattern.children.each do |scan|
        return false if not scan_finalize(scan)
      end
      pattern.finalized = pattern.final
      if not pattern.finalized
        assocs = MessagePattern.all(:pattern=>pattern)
        assocs.each do |asc|
          asc.destroy!
        end
        pattern.destroy!
      else
        pattern.active_filter = true
        pattern.save
      end
    end
    assocs = MessageScan.all(:scan=>scan)
    assocs.each do |asc|
      asc.destroy!
    end
    scan.destroy!
    @redis.rpush("filter", "update")
    return true
  end

  def pattern_remove(id)
    pattern = Pattern.get(id)
    if pattern
      assocs = MessagePattern.all(:pattern=>pattern)
      assocs.each do |asc|
        asc.destroy!
      end
      pattern.destroy!
    end
  end

  def pattern_finalize(id)
    pattern = Pattern.get(id.to_i)
    if not pattern.nil?
      pattern.final = true;
      pattern.save
    else
      return false
    end
    true
  end

  def pattern_unfinalize(id)
    pattern = Pattern.get(id.to_i)
    if not pattern.nil?
      pattern.final = false;
      pattern.save
    else
      return false
    end
    true
  end

  def pattern_save(pattern)
    pat = Pattern.get(pattern["id"])
    if pat
      pat.body = pattern["body"] if pattern["body"]
      pat.body_split = body_split(pat.body)
      pat.final = pattern["final"] if pattern["final"]
      signal = false
      if pattern["finalized"] and pat.active_filter != pattern["active_filter"]
        pat.active_filter = pattern["active_filter"]
        signal = true
      end
      pat.save
      @redis.rpush("filter", "update") if signal
    else
      return false
    end
    true
  end

  def results
    patterns = Pattern.all(:finalized=>true)

    output = patterns.map {|pattern| {pattern.name=>pattern.body}}

    file = Tempfile.new('patterns')
    file.write JSON.generate(output)
    file.close
    yield file.path
    file.unlink
  end

  def variables
    parsed = begin
      YAML.load(File.open("./variables.yml"))
    rescue ArgumentError => e
      return []
    end
  end
end