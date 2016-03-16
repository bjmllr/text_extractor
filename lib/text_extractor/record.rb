class TextExtractor
  class Record
    attr_reader :regexp, :factory, :values

    def initialize(regexp, factory: nil, values: [], fill: [])
      @regexp = regexp
      @factory = factory
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
      case factory
      when Hash
        build_extraction_by_hash(extracted)
      when Set
        build_extraction_by_set(extracted)
      when Class
        build_extraction_by_class(extracted)
      else
        extracted
      end
    end

    def build_extraction_by_hash(extracted)
      klass, params = factory.first
      klass.new(*extracted.values_at(*params))
    end

    def build_extraction_by_set(extracted)
      klass, params = factory.first
      values = params.each_with_object({}) do |param, hash|
        hash[param] = extracted[param]
      end
      klass.new(**values)
    end

    def build_extraction_by_class(extracted)
      if factory.ancestors.include?(Struct)
        factory.new(*extracted.values)
      else
        factory.new(**extracted)
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
  end # class Record
end # class TextExtractor
