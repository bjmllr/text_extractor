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
    value :this, /\w+/
    value :that, /\w+/

    record(strip: :left) do
      /
      This: #{this}
      That: #{that}
      /
    end
  end
end
