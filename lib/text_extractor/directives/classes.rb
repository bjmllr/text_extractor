require 'text_extractor/inline_value'

class TextExtractor
  class Directives
    # base class for line directives
    class Directive
      attr_reader :state

      def initialize(state, argument = nil)
        @state = state
        @argument = argument
        init if respond_to?(:init)
      end

      def values
        []
      end
    end

    # open a line group
    class Begin < Directive
      def init
        type = case @argument
               when '', nil
                 '?:'
               when '?:'
                 ''
               else
                 @argument
               end
        @group = group(type)
      end

      def group(*args)
        Group.new(*args)
      end

      def call
        state.current = nil
        state.groups.push @group
      end
    end

    # alternating capture group
    class Any < Begin
      def group(*args)
        AnyGroup.new(*args)
      end
    end

    # capture group that creates a value
    class Capture < Begin
      def group(name, *args)
        CaptureGroup.new(name, *args)
      end

      def values
        [InlineValue.new(@argument.to_sym)]
      end
    end

    # text that will be omitted from the regexp
    class Comment < Directive
      def call; end
    end

    # close a line group
    class End < Directive
      def call
        state.current = state.groups.pop.finish(state.newline?)
      end
    end

    # current line or group occurs 0 or 1 times
    class Maybe < Directive
      def call
        state.current = ['(?:', state.current, ')?']
      end
    end

    # repetition
    class Repeat < Directive
      def call
        @argument ||= '0,'
        state.current = ['(?:', state.current, "){#{@argument}}"]
      end
    end

    # skip to end of line
    class Rest < Directive
      def call
        state.current = if state.newline?
                          [state.current.chomp, '[^\\n]*\n']
                        else
                          [state.current, '[^\\n]*']
                        end
      end
    end
  end
end
