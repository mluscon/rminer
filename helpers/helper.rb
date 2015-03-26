require 'json'

def body_split(body)
  words = []
  body.split(" ").each_with_index do |word, i|
    if word.match(/^<<</)
      words.push({"word" => word, "variable" => true})
    else
      words.push({"word" => word, "variable" => false})
    end
  end
  JSON.generate(words)
end

