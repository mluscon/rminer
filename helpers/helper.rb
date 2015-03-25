require 'json'

def extract_words(body)
  words = []
  body.split(" ").each_with_index do |word, i|
    if not word.match(/^<<</)
      words.push([word, i])
    end
  end
  JSON.generate(words)
end

def extract_variables(body)
  words = []
  body.split(" ").each_with_index do |word, i|
    if word.match(/^<<</)
      words.push([word, i])
    end
  end
  JSON.generate(words)
end