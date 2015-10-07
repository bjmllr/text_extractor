require "minitest/autorun"

require_relative "../lib/text_extractor"
require_relative "examples"

# tests for TextExtractor
class TestTextExtractor < Minitest::Test
  N = Example::BGP::Neighbor

  def test_multiple_record_definitions_with_multiple_instances
    assert_equal N::OUTPUT1, N::EXTRACTOR1.scan(N::INPUT1)
  end

  VALUE = Example::ValueConversion
  def test_value_conversions
    assert_equal VALUE::OUTPUT, VALUE::EXTRACTOR.scan(VALUE::INPUT)
  end # def test_value_conversions

  FACTORY = Example::Factories
  def test_factories
    assert_equal FACTORY::OUTPUT, FACTORY::EXTRACTOR.scan(FACTORY::INPUT)
  end

  FILLDOWN = Example::Filldown

  def test_filldown_with_fill
    out = FILLDOWN::EXTRACTOR_FILL.scan(FILLDOWN::INPUT)
    assert_equal FILLDOWN::OUTPUT_FILL, out
  end

  def test_filldown_with_no_fill
    out = FILLDOWN::EXTRACTOR_NO_FILL.scan(FILLDOWN::INPUT)
    assert_equal FILLDOWN::OUTPUT_NO_FILL, out
  end
end # class TestTextExtractor < Minitest::Test
