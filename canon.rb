require 'yaml'

require 'variable.rb'
require 'helpers/helper.rb'

def canonize(patterns, msgs, separator)
  best = {}
  patterns.each do |pattern|
    regexp = build_filter(pattern, separator)
    filtered = []
    msgs.each do |msg|
      filtered << msg if regexp.match(msg.body)
    end
    best_pattern = find_best_pattern(pattern, filtered, separator)
    best[best_pattern] = filtered
  end
  best
end

def find_best_pattern(pattern, msgs, separator)
  pattern = pattern.split(separator)
  msgs = msgs.select{|msg| msg.body.split(separator).length == pattern.length}
  var_is = pattern.map.with_index {|x, i| x == 'VAR' ? i : nil}.compact
  var_is.each_with_index do |index, var_index|
    vars = []
    msgs.each do |msg|
      vars.push(find_best_var(msg.body.split(separator)[index]))
    end
    if vars.empty?
      best_var = Variable.new("90", "Var", "")
    else
      best_var = vars.max_by{|x| x.priority}
    end
    pattern[index] = "%{#{best_var.name}:var#{var_index+1}}<<#{best_var.regexp}>>"
  end
  pattern.join(" ")
end


def find_best_var( string )
  variables = []
  parsed = begin
    YAML.load(File.open("./variables.yml"))
  rescue ArgumentError => e
    $logger.error("Could not parse variables.yml: #{e.message}")
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

def build_filter(pattern, separator)
  reg = Regexp.escape pattern
  reg = "^" << reg << "$"
  Regexp.new(reg.gsub("VAR","[^\s]+"))
end
