require_relative 'record'

class TextExtractor
  class Guard < Record
    def initialize(_regexp, description:, **kwargs)
      super
      @description = description
    end

    def extraction(match, _fill)
      text = match[0]
      text = @factory.call(text) if @factory
      raise GuardError, "#{@description} near #{text.inspect}"
    end

    INDENTED = {
      description: 'indented line',
      factory: ->(e) { e },
      block: proc {
        /
        ^[^\n\S]+[^\n]*$
        /
      }
    }.freeze

    UNINDENTED = {
      description: 'unindented line',
      factory: ->(e) { e },
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
  end

  class GuardError < StandardError; end
end # class TextExtractor
