require_relative '../test_helper'
require 'text_extractor'

# checks that records that match an empty string will raise an exception when
# they are first defined
class TestEmptyRecord < Minitest::Test
  def test_totally_empty_record
    line = nil

    error = assert_raises(TextExtractor::EmptyRecordError) do
      TextExtractor.new do
        line = __LINE__
        record do
          //
        end
      end
    end

    trace = error.backtrace.inspect
    assert_match(/#{__FILE__}:#{line + 1}:in/, trace)
  end

  def test_single_newline_record
    assert_raises(TextExtractor::EmptyRecordError) do
      TextExtractor.new do
        record do
          /
          /
        end
      end
    end
  end

  def test_double_newline_record
    TextExtractor.new do
      record do
        /

        /
      end
    end
  end

  def test_match_any_record
    assert_raises(TextExtractor::EmptyRecordError) do
      TextExtractor.new do
        record do
          /.*/
        end
      end
    end
  end
end
