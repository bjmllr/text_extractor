class TextExtractor
  # represents a single execution of a TextExtractor
  class Extraction
    attr_reader :input, :extractor, :re, :pos, :matches, :values

    def initialize(input, extractor, fill = {})
      @input = input
      @extractor = extractor
      @fill = fill
      @pos = 0
      @matches = []
      @last_match = nil
    end

    def extraction_matches
      matches.flat_map do |match|
        extraction_match(match)
      end
    end

    def extraction_match(match)
      extractor.find_record_for(match).extraction(match, @fill)
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
