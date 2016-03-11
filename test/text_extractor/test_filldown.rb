require_relative '../test_helper'
require 'text_extractor'

class TestTextExtractorFilldown < Minitest::Test
  INPUT = unindent(<<-END)
      Philosophers:
      Rene Descartes
      Bertrand Russell

      Chemists:
      Alfred Nobel
      Marie Curie
    END

  EXTRACTOR_FILL = TextExtractor.new do
    value :occupation, /\w+/
    value :name, /\w+ \w+/
    filldown { /#{occupation}:/ }
    record(fill: :occupation) { /#{name}/ }
  end

  OUTPUT_FILL = [
    { occupation: 'Philosophers', name: 'Rene Descartes' },
    { occupation: 'Philosophers', name: 'Bertrand Russell' },
    { occupation: 'Chemists', name: 'Alfred Nobel' },
    { occupation: 'Chemists', name: 'Marie Curie' }
  ].freeze

  EXTRACTOR_NO_FILL = TextExtractor.new do
    value(:occupation, /\w+/)
    value(:name, /\w+ \w+/)
    filldown { /#{occupation}:/ }
    record { /#{name}/ }
  end

  OUTPUT_NO_FILL = [
    { name: 'Rene Descartes' },
    { name: 'Bertrand Russell' },
    { name: 'Alfred Nobel' },
    { name: 'Marie Curie' }
  ].freeze

  def test_filldown_with_fill
    assert_equal OUTPUT_FILL, EXTRACTOR_FILL.scan(INPUT)
  end

  def test_filldown_with_no_fill
    assert_equal OUTPUT_NO_FILL, EXTRACTOR_NO_FILL.scan(INPUT)
  end
end
