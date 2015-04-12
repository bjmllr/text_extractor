class TextExtractor
  # represents a single execution of a TextExtractor
  class Extraction
    attr_reader :input, :re, :pos, :matches

    def initialize(input, re)
      @input = input
      @re = re
      @pos = 0
      @matches = []
      @last_match = nil
    end

    def record_matches
      matches.map do |match|
        match.names.flat_map do |name|
          match[name] ? [name.to_sym, match[name]] : []
        end.each_slice(2).to_h
      end
    end

    def scan
      loop do
        match = input.match(re, pos)
        break unless match
        @pos = match.end(0)
        @matches << match
      end
      self
    end
  end # class Extraction
end # class TextExtractor
