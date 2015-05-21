class NaggapanVouk

  def run(msgs, sensitivity, separator)
    # build a frequency possition table
    split_msgs = msgs.map{|msg| msg.split(separator)}

    f_table = Hash.new
    split_msgs.each do |msg|
      msg.each_with_index do |word, index|
        if f_table[word]
          f_table[word][index] = f_table[word][index].to_i + 1
        else
          f_table[word] = Array.new
          f_table[word][index] = 1
        end
      end
    end

    # look up frequency for each line
    l_table = Hash.new
    split_msgs.each do |msg|
      l_table[msg] = msg.map.with_index{|word,poss| f_table[word][poss]}
    end

    # determine variable part of message
    results = Array.new
    l_table.each do |msg, freqs|
      treshold = mode(freqs)*sensitivity
      results << msg.map.with_index{|word, poss| freqs[poss] >= treshold ? word : 'VAR'}
    end

    results.map{|line| line.join(" ")}.uniq
  end

  def mode(values)
    count = Hash.new(0)
    values.each { |value| count[value] += 1 }
    count = count.sort_by { |k,v| v }.last[0]
  end

end
