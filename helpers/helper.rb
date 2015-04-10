require 'json'

def body_split(body)
  words = []
  var_reg = /(?<=>>).*(?=>>>)/
  body.split(" ").each_with_index do |word, i|
    if word.match(/^<<</)
      words.push({"word" => var_reg.match(word), "variable" => true})
    else
      words.push({"word" => word, "variable" => false})
    end
  end
  JSON.generate(words)
end

