class TextExtractor
  class Value
    attr_reader :id, :re

    def initialize(id, re, &block)
      @id = id
      @re = re
      @block = block
    end

    def convert(value)
      @block ? @block.call(value) : value
    rescue StandardError => e
      raise e.class,
            'in custom conversion of '\
            "value(#{id.inspect}, #{re.inspect}): #{e.message}"
    end
  end
end
