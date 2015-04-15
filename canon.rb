require 'yaml'

require './variable.rb'
require './helpers/helper.rb'



def build_filter( pattern )
  reg = Regexp.escape pattern
  reg = "^" << reg << "$"
  Regexp.new(reg.gsub("VAR","[^\s]+"))
end

def find_best_pattern(pattern, msgs, separator)
  pattern = pattern.split(separator)
  msgs = msgs.select{|msg| msg.split(separator).length == pattern.length}
  var_is = pattern.map.with_index {|x, i| x == 'VAR' ? i : nil}.compact
  var_is.each do |index|
    vars = []
    msgs.each do |msg|
      vars.push(find_best_var(msg.split(separator)[index]))
    end
    if vars.empty?
      best_var = Variable.new("90", "Var", "")
    else
      best_var = vars.max_by{|x| x.priority}
    end
    pattern[index] = "<<<" + best_var.name + best_var.regexp + ">>>"
  end
  pattern.join(" ")
end


def find_best_var( string )
  variables = []
  parsed = begin
    YAML.load(File.open("./variables.yml"))
  rescue ArgumentError => e
    STDERR.puts "Could not parse variables.yml: #{e.message}"
  end

  variables = []
  parsed.each do |var|
    new_var = Variable.new(var["priority"], var["short"], var["regexp"])
    variables.push new_var
  end
  variables

  match=[]
  variables.each do |var|
    reg = Regexp.new("^" + var.regexp + "$")
    match << var if reg.match(string)
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