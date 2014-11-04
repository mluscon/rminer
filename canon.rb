
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
      vars.push( find_best_var( msg.split(separator)[index] ))
    end
  end
  pattern.join(" ")
end


def find_best_var( string )
  variables = []
variables.push Variable.new(10, "<<INT>>", Regexp.new("^[0-9]+$"))
variables.push Variable.new(20, "<<FLOAT>>", Regexp.new("^[-+]?[0-9]*\\.?[0-9]+$"))
variables.push Variable.new(30, "<<BOOLEAN>>", Regexp.new("^\\btrue\\b|\\bfalse\\b$"))
variables.push Variable.new(40, "<<WORD>>", Regexp.new("^[a-zA-Z]+$"))
variables.push Variable.new(50, "<<STRING>>", Regexp.new("^[-._:/a-zA-Z0-9\\\\]+$"))
variables.push Variable.new(60, "<<EMPTY>>", Regexp.new("^$"))
variables.push Variable.new(70, "<<ALPHANUM>>", Regexp.new("^[_a-zA-Z0-9]+$"))
variables.push Variable.new(80, "<<ALPHANUMTEXT>>", Regexp.new("^[-._a-zA-Z0-9]+$"))
variables.push Variable.new(90, "<<ARBITRARY>>", Regexp.new("^[^\n\r]+$"))
variables.push Variable.new(100, "<<VAR>>", Regexp.new("^[^\s]+$"))

  match=[]
  variables.each do |var|
    puts var.name + " : " + string if var.regexp.match(string)
    match << var if var.regexp.match(string)
  end
  best = match.min_by{|x| x.priority}
  best
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