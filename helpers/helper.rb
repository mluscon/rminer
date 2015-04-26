require 'json'

require './variable.rb'

def body_split(body)
  words = []
  var_type = /(?<=%{).+?(?=:)/
  var_reg = /(?<=<<).+?(?=>>)/
  var_name = /(?<=:).+?(?=})/
  body.split(" ").each_with_index do |word, i|
    if word.match(/^%{/)
      words.push({"word" => var_reg.match(word), "variable" => true, "type" => var_type.match(word), "name" => var_name.match(word) })
    else
      words.push({"word" => word, "variable" => false})
    end
  end
  JSON.generate(words)
end

def parse_variables(variables)
  list = []
  variables.each do |var|
    new_var = Variable.new(var["priority"], var["short"], var["regexp"])
    list.push new_var
  end
  list
end

def pattern_name(pattern)
  pattern = JSON.parse pattern
  name = ""
  pattern.each do |word|
    if word["variable"] == false
      name = name + " " + word["word"]
    end
    break if name.split.length == 2
  end
  name
end
