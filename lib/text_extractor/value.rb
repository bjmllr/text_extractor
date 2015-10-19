class TextExtractor
  class Value
    attr_reader :id, :re

    def initialize(id, re, &block)
      @id = id
      @re = re
      @block = block if block_given?
    end

    def convert(value)
      @block ? @block.call(*value) : value
    end
  end
end