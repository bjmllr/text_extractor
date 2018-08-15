require_relative '../test_helper'
require 'text_extractor'

class TestTextExtractorSkip < Minitest::Test
  INPUT = unindent(<<-END)
    Matrix, The
      Genre: Science Fiction
    Magnificent Seven, The
      Genre: Western
    Get Out
      Genre: Horror
    END

  EXTRACTOR = TextExtractor.new do
    value :title, /[^\n]+/
    value :genre, /[^\n]+/

    skip do
      /
      #{title}
        Genre: Western
      /
    end

    record do
      /
      #{title}
        Genre: #{genre}
      /
    end
  end

  OUTPUT = [
    { title: 'Matrix, The', genre: 'Science Fiction' },
    { title: 'Get Out', genre: 'Horror' }
  ].freeze

  def test_skip
    assert_equal OUTPUT, EXTRACTOR.scan(INPUT)
  end
end
