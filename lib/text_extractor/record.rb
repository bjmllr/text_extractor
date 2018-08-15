require_relative 'directives'

class TextExtractor
  class Record
    attr_reader :regexp, :factory, :values

    # rubocop: disable Metrics/ParameterLists
    def initialize(
          regexp,
          factory: nil,
          values: [],
          fill: [],
          directives: true,
          inline: [],
          extractor_values: {},
          strip: nil,
          **_kwargs
    )
      @factory = factory
      @constructor = FactoryAnalyzer.new(factory).to_proc
      @extractor_values = extractor_values
      @values = values.map { |val| [val.id, val] }.to_h
      initialize_inline_values(inline)
      @default_values = values.map { |val| [val.id, nil] }.to_h
      @regexp = build_regexp(regexp, directives, strip)
      @fill = Array(fill)
    end
    # rubocop: enable Metrics/ParameterLists

    # @return Array
    def extraction(match, fill)
      extracted = {}.merge!(@default_values)
                    .merge!(extract_fills(fill))
                    .merge!(extract_values(match))
      [build_extraction(extracted)]
    end

    def build_extraction(extracted)
      return extracted unless @constructor
      @constructor.call(extracted)
    end

    def build_regexp(regexp, directives, strip)
      stripped = strip_regexp(regexp, strip)
      expanded = expand_regexp(stripped, directives)
      ignore_regexp(expanded, strip)
    end

    def strip_regexp(regexp, strip)
      lines = regexp.source.split("\n")
      prefix = lines.last
      if lines.first =~ /\A\s*\z/ && prefix =~ /\A\s*\z/
        lines.shift
        lines = lines.map { |s| s.gsub(prefix, '') }
        lines = lines.map(&regexp_line_stripper(strip))
      end
      Regexp.new(lines.join("\n"), regexp.options)
    end

    def regexp_line_stripper(strip)
      case strip
      when :left  then ->(s) { s.lstrip }
      when :right then ->(s) { s.rstrip }
      when :both  then ->(s) { s.strip }
      when nil, false then ->(s) { s }
      else raise "Unknown strip option: #{strip}"
      end
    end

    def expand_regexp(regexp, directives)
      if directives
        expander = Directives.new(regexp)
        expanded = expander.expand
        expander.values.each do |value|
          values[value.id] = @extractor_values.fetch(value.id, value)
        end
        expanded
      else
        regexp
      end
    end

    def ignore_regexp(regexp, strip)
      return regexp unless strip
      lines = regexp.source.split("\n").map(&regexp_line_ignorer(strip))
      Regexp.new(lines.join("\n"), regexp.options)
    end

    def regexp_line_ignorer(strip)
      case strip
      when :left  then ->(s) { "\[ \\t\\r\\f]*#{s}" }
      when :right then ->(s) { "#{s}\[ \\t\\r\\f]*" }
      when :both  then ->(s) { "\[ \\t\\r\\f]*#{s}\[ \\t\\r\\f]*" }
      else raise "Unknown ignore whitespace option: #{strip}"
      end
    end

    def match(string, pos = 0)
      @regexp.match(string, pos)
    end

    def source
      @regexp.source
    end

    def options
      @regexp.options
    end

    def extract_fills(fill)
      @fill.zip(fill.values_at(*@fill)).to_h
    end

    def extract_values(match)
      values.keys.map { |id| [id, values[id].convert(match[id])] }.to_h
    end

    def initialize_inline_values(inline_values)
      inline_values.each do |value|
        @values[value] = @extractor_values
                         .fetch(value) { InlineValue.new(value) }
      end
    end

    # converts the value of the factory option to a constructor proc
    class FactoryAnalyzer
      def initialize(factory)
        @params = nil

        case factory
        when Hash
          @klass, @params = factory.first
        else
          @klass = factory
        end
      end

      def to_proc
        if @params
          explicit
        elsif @klass.is_a?(Proc)
          @klass
        elsif @klass
          implicit
        end
      end

      private

      def explicit
        case @params
        when Array
          positional
        when Set
          keyword
        end
      end

      def positional
        ->(extracted) { @klass.new(*extracted.values_at(*@params)) }
      end

      def keyword
        lambda do |extracted|
          values = @params.each_with_object({}) do |param, hash|
            hash[param] = extracted[param]
          end
          @klass.new(**values)
        end
      end

      def implicit
        if @klass.ancestors.include?(Struct)
          ->(extracted) { @klass.new(*extracted.values) }
        else
          ->(extracted) { @klass.new(**extracted) }
        end
      end
    end # class FactoryAnalyzer
  end # class Record
end # class TextExtractor
