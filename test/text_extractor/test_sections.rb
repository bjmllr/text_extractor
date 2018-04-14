require_relative '../test_helper'
require 'text_extractor'

class TestTextExtractorSections < Minitest::Test
  INPUT = unindent(<<-END).freeze
  One
  Two

  Three
  Four
  END

  OUTPUT = %W[One\nTwo\n Three\nFour\n\n].freeze

  EXTRACTOR = TextExtractor.new do
    section(/\n\n+/, "\n")
  end

  def test_sections
    assert_equal OUTPUT, EXTRACTOR.sections(INPUT)
  end

  FILL_INPUT = unindent(<<-END).freeze
  :title
  One

  Two
  END

  FILL_OUTPUT = [{ val: 'One', title: 'title' },
                 { val: 'Two', title: 'title' }].freeze

  FILL_EXTRACTOR = TextExtractor.new do
    value(:title, /\w+/)
    value(:val, /\w+/)

    section(/\n\n+/, "\n")

    filldown do
      /
      :#{title}
      /
    end

    record(fill: :title) do
      /
      #{val}
      /
    end
  end

  def test_sections_with_filldown
    assert_equal FILL_OUTPUT, FILL_EXTRACTOR.scan(FILL_INPUT)
  end
end
