require_relative 'record'

class TextExtractor
  class Filldown < Record
    def initialize(*args, **kwargs)
      @filldown_output = kwargs.delete(:output) || false
      super(*args, **kwargs)
    end

    def extraction(match, fill)
      fill.merge!(extract_values(match))

      if @filldown_output
        super
      else
        []
      end
    end
  end # class Filldown < Record
end # class TextExtractor
