class TextExtractor
  class Record
    attr_reader :regexp, :factory

    def initialize(regexp, factory = nil)
      @regexp = regexp
      @factory = factory
    end

    def extraction(fill)
      hash = fill.merge(yield)
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
