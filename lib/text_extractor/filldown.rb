require_relative 'record'

class TextExtractor
  class Filldown < Record
    def extraction(match, fill)
      fill.merge!(extract_values(match))
      []
    end
  end # class Filldown < Record
end # class TextExtractor
