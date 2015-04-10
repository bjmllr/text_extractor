class TextExtractor
  # represents a single execution of a TextExtractor
  class Extraction
    attr_accessor :input, :pos, :matches, :last_match

    def initialize(input)
      @input = input
      @pos = 0
      @matches = []
      @last_match = nil
    end

    def last_match_end_position
      cs = last_match.captures
      last_match.end(cs.size - cs.reverse.find_index { |x| x })
    end

    def record_matches
      matches.map do |match|
        match.names.flat_map do |name|
          match[name] ? [name.to_sym, match[name]] : []
        end.each_slice(2).to_h
      end
    end

    def match(re)
      @last_match = input.match(re, pos)
      return nil unless last_match
      @pos = last_match_end_position
      @matches << last_match
      @last_match
    end
  end # class Extraction
end # class TextExtractor
