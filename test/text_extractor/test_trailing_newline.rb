require_relative '../test_helper'
require 'text_extractor'

class TestTextExtractorTrailingNewline < Minitest::Test
  INPUT = "Char: a\nChar: b".freeze

  OUTPUT = [
    {
      char: 'a'
    }, {
      char: 'b'
    }
  ].freeze

  EXTRACTOR = TextExtractor.new do
    value :char, /./

    record do
      /
      Char: #{char}
      /
    end
  end

  IMPROVED_EXTRACTOR = TextExtractor.new do
    append_newline true

    value :char, /./

    record do
      /
      Char: #{char}
      /
    end
  end

  def test_trailing_newline_handling_global
    refute_equal OUTPUT, EXTRACTOR.scan(INPUT)
    TextExtractor.append_newline = true
    assert_equal OUTPUT, EXTRACTOR.scan(INPUT)
    TextExtractor.append_newline = false
  end

  def test_trailing_newline_handling
    assert_equal OUTPUT, IMPROVED_EXTRACTOR.scan(INPUT)
  end
end
