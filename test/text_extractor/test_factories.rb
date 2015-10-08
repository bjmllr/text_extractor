require_relative "../test_helper"
require "text_extractor"

class TestTextExtractorFactories < Minitest::Test
  INPUT = unindent(<<-END)
    whowhere Rene Descartes France
    where America
    whowhere Bertrand Russell Wales
    where China
    END

  WhoWhere = Struct.new(:person, :place)
  Where = Struct.new(:place)

  EXTRACTOR = TextExtractor.new do
    value :person, /\w+ \w+/
    value :place, /\w+/
    record(factory: WhoWhere) { /whowhere #{person} #{place}/ }
    record(factory: Where) { /where #{place}/ }
  end

  OUTPUT = [
    WhoWhere.new("Rene Descartes", "France"),
    Where.new("America"),
    WhoWhere.new("Bertrand Russell", "Wales"),
    Where.new("China")
  ]

  def test_factories
    assert_equal OUTPUT, EXTRACTOR.scan(INPUT)
  end
end
