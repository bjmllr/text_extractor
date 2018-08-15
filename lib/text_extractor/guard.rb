require_relative 'record'

class TextExtractor
  class Guard < Record
    def initialize(_regexp, description:, **kwargs)
      super
      @description = description
      @factory ||= :itself.to_proc
    end

    def extraction(match, _fill)
      text = @factory.call(match[0])
      raise GuardError, "#{@description} near #{text.inspect}"
    end
  end

  INDENTED = {
    description: 'indented line',
    block: proc {
      /
      ^[^\n\S]+[^\n]*$
      /
    }
  }.freeze

  UNINDENTED = {
    description: 'unindented line',
    block: proc {
      /
      ^\S+[^\n]*$
      /
    }
  }.freeze

  DEFAULT = [
    INDENTED,
    UNINDENTED
  ].freeze

  class GuardError < StandardError; end
end # class TextExtractor
