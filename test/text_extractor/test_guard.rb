require_relative '../test_helper'
require 'text_extractor'

class TestTextExtractorGuard < Minitest::Test
  INPUT = unindent(<<-END)
    Syracuse
    Memphis
    Waterloo
    La Paz
    END

  EXTRACTOR = TextExtractor.new do
    value :name, /\S+/

    record do
      /
      #{name}
      /
    end

    guard description: 'anything else', factory: ->(e) { e.strip } do
      /
      [^\n]+
      /
    end
  end

  REORDERED_EXTRACTOR = TextExtractor.new do
    guards(
      description: 'anything else',
      factory: ->(e) { e.strip },
      block: proc {
        /
        [^\n]+
        /
      }
    )

    value :name, /\S+/

    record do
      /
      #{name}
      /
    end
  end

  def test_guard
    error = assert_raises(TextExtractor::GuardError) do
      EXTRACTOR.scan(INPUT)
    end
    assert_match(/anything else near "La Paz"/, error.message)
  end

  def test_reordered_guard
    error = assert_raises(TextExtractor::GuardError) do
      REORDERED_EXTRACTOR.scan(INPUT)
    end
    assert_match(/anything else near "La Paz"/, error.message)
  end
end
