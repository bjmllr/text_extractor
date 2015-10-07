class TextExtractor
  class Record
    attr_reader :regexp, :factory

    def initialize(regexp, factory = nil, fill: [])
      @regexp = regexp
      @factory = factory
      @fill = Array(fill)
    end

    def extraction(fill)
      hash = @fill.zip(fill.values_at(*@fill)).to_h.merge(yield)
      factory ? factory.new(*hash.values) : hash
    end

    def match(string, pos = 0)
      @regexp.match(string, pos)
    end

    def source
      @regexp.source
    end
  end # class Record
end # class TextExtractor
