class TextExtractor
  class Record
    attr_reader :regexp, :factory, :values

    def initialize(regexp, factory: nil, values: [], fill: [])
      @regexp = regexp
      @factory = factory
      @constructor = FactoryAnalyzer.new(factory).to_proc
      @values = values.map { |val| [val.id, val] }.to_h
      @default_values = values.map { |val| [val.id, nil] }.to_h
      @fill = Array(fill)
    end

    def extraction(match, fill)
      extracted = {}.merge!(@default_values)
                    .merge!(extract_fills fill)
                    .merge!(extract_values match)
      build_extraction(extracted)
    end

    def build_extraction(extracted)
      return extracted unless @constructor
      @constructor.call(extracted)
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

    # converts the value of the factory option to a constructor proc
    class FactoryAnalyzer
      def initialize(factory)
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
