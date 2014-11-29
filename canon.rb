require 'yaml'

class Variable
  attr_accessor :name, :priority, :regexp

  def initialize(priority, name, regexp)
    @priority=priority
    @name=name
    @regexp=regexp
  end
end

variables = []

def build_filter( pattern )
  reg = Regexp.escape pattern
  reg = "^" << reg << "$"
  Regexp.new(reg.gsub("VAR","[^\s]+"))
end

def find_best_pattern(pattern, msgs, separator)
  pattern = pattern.split(separator)
  var_is = pattern.map.with_index {|x, i| x == 'VAR' ? i : nil}.compact
  var_is.each do |index|
    vars = []
    msgs.each do |msg|
      vars.push(find_best_var(msg.split(separator)[index]))
    end
    best_var = vars.max_by{|x| x.priority}
    pattern[index] = best_var.name + "<<<" + best_var.source + ">>>"
  end
  pattern.join(" ")
end


def find_best_var( string )

  parsed = begin
    YAML.load(File.open("./variables.yml"))
  rescue ArgumentError => e
    STDERR.puts "Could not parse variables.yml: #{e.message}"
  end

  variables = []
  parsed.each do |var|
    new_var = Variable.new(var["priority"], var["short"], Regexp.new(var["regexp"]))
    variables.push new_var
  end

  match=[]
  variables.each do |var|
    match << var if var.regexp.match(string)
  end
  match.min_by{|x| x.priority}
end

def canonize(patterns, msgs, separator)

  best = {}
  patterns.keys.each do |pattern|
    regexp = build_filter(pattern)
    filtered = []
    patterns[pattern].each do |msg_id|
      msg = msgs.get(msg_id).body
      filtered.push(msg) if regexp.match(msg)
    end
    best_pattern = find_best_pattern(pattern, filtered, separator)
    best[best_pattern] = patterns[pattern]
  end

  best

end