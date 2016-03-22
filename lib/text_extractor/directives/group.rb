class TextExtractor
  class Directives
    # a line group
    class Group
      def initialize(type, *args)
        @type = type
        @lines = args
      end

      def <<(item)
        @lines << item
      end

      def to_a
        @lines
      end

      def chomp(newline)
        return if @lines.empty? || newline
        tail = @lines[-1]
        if tail.is_a?(Array)
          tail = tail[-1] while tail[-1].is_a?(Array)
          tail[-2] = tail[-2].chomp
        else
          @lines[-1] = @lines[-1].chomp
        end
      end

      def finish(newline)
        chomp(newline)
        join
      end

      def join
        ["(#{@type}", *@lines, ')']
      end
    end

    # a line group where each line (or subgroup) is an alternative
    class AnyGroup < Group
      def join
        ['(?:', *@lines.flat_map { |e| [e, '|'] }[0..-2], ')']
      end
    end
  end
end
