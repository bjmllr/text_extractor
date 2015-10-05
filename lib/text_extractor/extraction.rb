class TextExtractor
  # represents a single execution of a TextExtractor
  class Extraction
    attr_reader :input, :extractor, :re, :pos, :matches

    def initialize(input, extractor)
      @input = input
      @extractor = extractor
      @re = extractor.to_re
      @pos = 0
      @matches = []
      @last_match = nil
    end

    def record_matches
      matches.map do |match|
        match.names.flat_map do |name|
          record_match(match, name)
        end.each_slice(2).to_h
      end
    end

    def record_match(match, name)
      return [] unless match[name]
      symbol = name.to_sym
      [symbol, convert_value(symbol, match[name])]
    end

    def convert_value(symbol, value)
      return value unless extractor.converters.key?(symbol)
      extractor.converters[symbol].call(value)
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
