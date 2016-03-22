require_relative '../test_helper'
require 'text_extractor/directives'

class TextExtractor
  class TestDirectives < Minitest::Test
    def expand(re)
      TextExtractor.expand_directives(re)
    end

    def test_comment_directive
      input = /foo #. this is a comment/
      expected = /foo/
      assert_equal expected, expand(input)
    end

    def test_avoid_directive
      input = /foo[ ]#.ng/
      assert_equal input, expand(input)
    end

    def test_single_line_group
      input =
        /#.begin
blah
#.end/
      expected = /(?:blah)/
      assert_equal expected, expand(input)
    end

    def test_multiple_line_group
      input = /#.begin
blah
bloo
#.end/
      expected = /(?:blah
bloo)/
      assert_equal expected, expand(input)
    end

    def test_consecutive_line_group
      input = /#.begin
blah
#.end
#.begin
bloo
#.end/
      expected = /(?:blah
)(?:bloo)/
      assert_equal expected, expand(input)
    end

    def test_nested_line_group
      input = /#.begin
before
#.begin
during
#.end
after
#.end
/
      expected = /(?:before
(?:during
)after
)/
      assert_equal expected, expand(input)
    end

    def test_maybe
      input = /maybe this #.maybe
/
      expected = /(?:maybe this
)?/
      assert_equal expected, expand(input)
    end

    def test_group_maybe
      input = /#.begin
maybe this
and also this
#.end.maybe/
      expected = /(?:(?:maybe this
and also this))?/
      assert_equal expected, expand(input)
    end

    def test_any
      input = /#.any
this
that
#.end/
      expected = /(?:this
|that)/
      assert_equal expected, expand(input)
    end

    def test_or_triple
      input = /#.any
this
that
the other
#.end/
      expected = /(?:this
|that
|the other)/
      assert_equal expected, expand(input)
    end

    def test_or_group
      input = /#.any
#.begin
this
and
that
#.end
#.begin
the
other
#.end
#.end/
      expected = /(?:(?:this
and
that
)|(?:the
other))/
      assert_equal expected, expand(input)
    end

    def test_repeat_kleene_star
      input = /asdf #.repeat/
      expected = /(?:asdf){0,}/
      assert_equal expected, expand(input)
    end

    def test_repeat_range
      input = /asdf #.repeat(1,2)/
      expected = /(?:asdf){1,2}/
      assert_equal expected, expand(input)
    end

    def test_repeat_no_min
      input = /asdf #.repeat(,2)/
      expected = /(?:asdf){,2}/
      assert_equal expected, expand(input)
    end

    def test_repeat_group
      input = /#.begin
one
two
#.end.repeat/
      expected = /(?:(?:one
two)){0,}/
      assert_equal expected, expand(input)
    end

    def test_repeat_nested_group
      input = /#.begin
one #.repeat(3)
two #.repeat(2)
#.end
/
      expected = /(?:(?:one
){3}(?:two
){2})/
      assert_equal expected, expand(input)
    end

    def test_rest
      input = /asdf #.rest/
      expected = /asdf[^\n]*/
      assert_equal expected, expand(input)
    end
  end
end
