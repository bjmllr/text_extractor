class TextExtractor
  # represents a single execution of a TextExtractor
  class Extraction
    attr_reader :input, :extractor, :re, :pos, :matches

    def initialize(input, extractor)
      @input = input
      @extractor = extractor
      @pos = 0
      @matches = []
      @last_match = nil
    end

    def extraction_matches
      @fill = {}
      matches.flat_map do |match|
        extraction_match(match)
      end
    end

    def extraction_match(match)
      record = extractor.find_record_for(match)
      if record.is_a?(Filldown)
        @fill.merge!(match_to_hash(match))
        []
      else
        [record_match(record, match)]
      end
    end

    def record_match(record, match)
      factory = record.factory
      hash = @fill.merge(match_to_hash(match))
      factory ? factory.new(*hash.values) : hash
    end

    def match_to_hash(match)
      match.names.flat_map do |name|
        value_pair(match, name)
      end.each_slice(2).to_h
    end

    def value_pair(match, name)
      return [] if !match[name] || name.start_with?("__")
      symbol = name.to_sym
      [symbol, convert_value(symbol, match[name])]
    end

    def convert_value(symbol, value)
      return value unless extractor.converters.key?(symbol)
      extractor.converters[symbol].call(value)
    end

    def scan
      re = extractor.to_re
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
