class TextExtractor
  class Record
    attr_reader :regexp, :values

    def initialize(regexp, factory: nil, values: [], fill: [])
      @regexp = regexp
      @constructor = analyze_factory(factory)
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

    def analyze_factory(factory)
      case factory
      when Hash
        analyze_factory_explicit(factory)
      when Class
        analyze_factory_implicit(factory)
      end
    end

    def analyze_factory_explicit(factory)
      klass, params = factory.first
      case params
      when Array
        analyze_factory_explicit_positional(klass, params)
      when Set
        analyze_factory_explicit_keyword(klass, params)
      end
    end

    def analyze_factory_explicit_positional(klass, params)
      ->(extracted) { klass.new(*extracted.values_at(*params)) }
    end

    def analyze_factory_explicit_keyword(klass, params)
      lambda do |extracted|
        values = params.each_with_object({}) do |param, hash|
          hash[param] = extracted[param]
        end
        klass.new(**values)
      end
    end

    def analyze_factory_implicit(factory)
      if factory.ancestors.include?(Struct)
        ->(extracted) { factory.new(*extracted.values) }
      else
        ->(extracted) { factory.new(**extracted) }
      end
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
  end # class Record
end # class TextExtractor
