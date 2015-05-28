require 'set'

class Iplom

  def initialize
    @clusters = Array.new
  end

  def run(msgs, sensitivity, separator)
    @patterns = Array.new

    split_msgs = msgs.map{|msg| msg.split(separator)}

    # split by length
    sorted = Hash.new
    split_msgs.each do |msg|
      if sorted[msg.length]
        sorted[msg.length] << msg
      else
        sorted[msg.length] = [msg]
      end
    end

    results = Array.new
    sorted.each do |key, msgs|
      split2(msgs, sensitivity)
    end

    patterns = Array.new
    @clusters.each{|cluster| patterns = patterns << find_patterns(cluster, sensitivity)}
    @clusters = Array.new
    patterns.uniq
  end

  def split2(msgs, sensitivity)

    # find a word possition with the least number of unique words
    unique_words = uniq_words_in_col(msgs)
    lengths = unique_words.map{|words| words.length}
    min = lengths.min
    split_pos = lengths.find_index(min)
    # split by a word on selected possition
    split = split_by_pos(split_pos, msgs)

    split.values.each do |msgs|
      split3(msgs)
    end
  end

  def split3(msgs)

    p1, p2 = get_possitions(msgs)

    words = uniq_words_in_col(msgs)

    if words[p1].length > words[p2].length
      p = p2
      p2 = p1
      p1 = p
    end
    puts words[p1].length
    puts words[p2].length

    if words[p1].length/words[p2].length.to_f < sensitivity
      @clusters << msgs
    else
      split = split_by_pos(p1, msgs)
      split.values.each do |msgs|
        @clusters << msgs
      end
    end
  end

  def split_by_pos(pos, msgs)
    split = Hash.new
    msgs.each do |msg|
      if split[msg[pos]]
        split[msg[pos]] << msg
      else
        split[msg[pos]] = [msg]
      end
    end
    split
  end

  def find_patterns(msgs, sensitivity)
    # build a frequency possition table
    uniq = uniq_words_in_col(msgs).map{|msg| msg.length}

    pattern = msgs[0].map.with_index{|word, index| uniq[index] == 1 ? word : 'VAR'}
    pattern.join(" ")
  end

  def get_possitions(msgs)

    if msgs[0].length == 2
      return 0, 1
    end

    tokens_count = uniq_words_in_col(msgs).map{|words| words.length}
    freqs = get_freq(tokens_count)
    # [[value, frequency],...]
    # find most frequent frequency :) other than one
    freq_card = freqs[0]
    freqs.each do |value, freq|
      freq_card = [value, freq] if freq_card[0] == 1
    end

    # find possitions of those frequencies
    p1, p2 = nil
    if freq_card[1] > 1
      tokens_count.each_with_index do |freq, pos|
        if p1.nil? and freq_card[0] == freq
          p1 = pos
          next
        end
        if p2.nil? and freq_card[0] == freq
          p2 = pos
          break
        end
      end
    else
      p1 = tokens_count.find_index(freq_card[0])
      p2 = tokens_count.find_index(freqs[1][0])
    end
    return p1, p2
  end

  def get_freq(values)
    count = Hash.new(0)
    values.each {|value| count[value] += 1}
    count = count.sort_by {|k,v| k}.reverse
  end

  def uniq_words_in_col(msgs)
    occ_table = []
    msgs.each do |msg|
      msg.each_with_index do |word, possition|
        if occ_table[possition]
          occ_table[possition] << word
        else
          occ_table[possition] = Set.new [word]
        end
      end
    end
    occ_table
  end

  def max_occ_for_col(msgs)
    f_table = []
    msgs.each do |msg|
      msg.each_with_index do |word, possition|
        if f_table[possition]
          f_table[possition][word] = f_table[possition][word].to_i + 1
        else
          f_table[possition] = {word => 1}
        end
      end
    end
    length = msgs.length
    f_table.map {|poss| f_table[poss].values.max / length}
  end

  def mode(values)
    count = Hash.new(0)
    values.each { |value| count[value] += 1 }
    count = count.sort_by { |k,v| v }.last[0]
  end

end
