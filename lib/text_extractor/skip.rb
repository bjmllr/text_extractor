require_relative 'record'

class TextExtractor
  class Skip < Record
    def extraction(*)
      []
    end
  end # class Skip < Record
end # class TextExtractor
