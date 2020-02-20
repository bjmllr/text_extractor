require_relative '../test_helper'
require 'text_extractor'

class TestTextExtractorStrip < Minitest::Test
  INPUT = unindent(<<-END)
  This: a
   That: b
   This: c
  That: d
  END

  OUTPUT = [
    {
      this: 'a',
      that: 'b'
    }, {
      this: 'c',
      that: 'd'
    }
  ].freeze

  EXTRACTOR = TextExtractor.new do
    strip :left

    value :this, /\w+/
    value :that, /\w+/

    record do
      /
      This: #{this}
      That: #{that}
      /
    end
  end

  def test_strip_left
    assert_equal OUTPUT, EXTRACTOR.scan(INPUT)
  end
end
