require 'text_extractor/value'

class TextExtractor
  # represents a value given by a .capture directive
  class InlineValue < Value
    def initialize(id, &block)
      @id = id
      @block = block
    end

    alias re id
  end
end
