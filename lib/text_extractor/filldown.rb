class TextExtractor
  class Filldown < Record
    def extraction(fill)
      fill.merge!(yield)
      []
    end
  end # class Filldown < Record
end # class TextExtractor
