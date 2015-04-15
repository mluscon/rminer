require 'json'

require './variable.rb'

def body_split(body)
  words = []
  var_type = /(?<=<<).+?(?=>>)/
  var_reg = /(?<=>>).+?(?=>>>)/
  body.split(" ").each_with_index do |word, i|
    if word.match(/^<<</)
      words.push({"word" => var_reg.match(word), "variable" => true, "type" => var_type.match(word)})
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