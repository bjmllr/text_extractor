class TextExtractor
  class Record
    attr_reader :regexp, :factory

    def initialize(regexp, factory = nil)
      @regexp = regexp
      @factory = factory
    end

    def match(string, pos = 0)
      @regexp.match(string, pos)
    end

    def source
      @regexp.source
    end
  end # class Record
end # class TextExtractor
