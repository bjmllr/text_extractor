require_relative '../test_helper'
require 'text_extractor'

class TextExtractor
  class TestInlineValues < Minitest::Test
    def test_capture_line_group
      extractor = TextExtractor.new do
        record do
          /
          before
          #.capture(foo)
            blah\d+
          #.end
          after
          /
        end
      end

      input = <<-END
before
  blah1
after
before
  blah2
after
      END

      expected = [
        { foo: "  blah1\n" },
        { foo: "  blah2\n" }
      ]

      assert_equal expected, extractor.scan(input)
    end

    def test_capture_line_group_with_conversion
      extractor = TextExtractor.new do
        inline :foo, &:strip

        record do
          /
          before
          #.capture(foo)
            blah\d+
          #.end
          after
          /
        end
      end

      input = <<-END
before
  blah1
after
before
  blah2
after
      END

      expected = [
        { foo: 'blah1' },
        { foo: 'blah2' }
      ]

      assert_equal expected, extractor.scan(input)
    end

    def test_capture_using_standard_syntax
      extractor = TextExtractor.new do
        inline :foo, &:to_i

        record(inline: [:foo]) do
          /
          before(?<foo>\d)after
          /
        end
      end

      input = <<-END
before3after
before2after
END

      expected = [
        { foo: 3 },
        { foo: 2 }
      ]

      assert_equal expected, extractor.scan(input)
    end
  end
end
