require 'rubygems'

require './canon.rb'

Entry = Struct.new(:freqs, :msgs)

def mode( values )
  count = Hash.new(0)
  values.each { |value| count[value] += 1 }
  count = count.sort_by { |k,v| v }.last[0]
end


def analyze(sensitivity, msgs, separator)
  f_table = {}

  msgs.each do | msg |
    msg.body.split(separator).each_with_index do | word, possition |

      if f_table.has_key?(word)
        f_entry = f_table[word]
        if f_entry.freqs[possition]
          f_entry.freqs[possition]+=1
          f_entry.msgs[possition].push(msg.id)
        else
          f_entry.freqs[possition]=1
          f_entry.msgs[possition]=Array.new
          f_entry.msgs[possition].push(msg.id)
        end

      else
        f_entry = Entry.new( Array.new, Array.new)
        f_entry.msgs[possition]=Array.new
        f_entry.freqs[possition]=1
        f_entry.msgs[possition].push(msg.id)
        f_table.store(word, f_entry)

      end
    end
  end

  results = Array.new

  msgs.each do | msg |
    msg = msg.body.split(separator)
    freqs = Array.new
    msg.each_with_index do | word, possition |
      freqs.push(f_table[word].freqs[possition])
    end
    treshold = mode(freqs)*sensitivity
    constant = freqs.map.with_index { | x, i | x >= treshold ? msg[i] : 'VAR' }
    results.push(constant.join(' '))
  end

  results.uniq!
  output = {}

  results.each do |msg|
    output[msg] = []
    msg.split(separator).each_with_index do |word, possition|
      if word != 'VAR'
        output[msg] += f_table[word].msgs[possition]
      end
      output[msg].uniq!
    end
  end

  output

  canon = canonize(output, msgs, separator)

  canon
end








