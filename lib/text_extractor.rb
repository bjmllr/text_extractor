require_relative 'text_extractor/extraction'
require_relative 'text_extractor/filldown'
require_relative 'text_extractor/guard'
require_relative 'text_extractor/record'
require_relative 'text_extractor/skip'
require_relative 'text_extractor/value'
require_relative 'text_extractor/inline_value'

# represents an extractor definition
class TextExtractor
  attr_reader :records, :values

  # rubocop: disable Metrics/MethodLength
  def initialize(&block)
    raise "#{self.class}.new requires a block" unless block
    @values = {}
    @fill = {}
    @values = {}
    @records = []
    @filldowns = []
    @current_record_values = []
    @section_delimiter = nil
    @section_terminator = nil
    @append_guards = []
    instance_exec(&block)
    @append_guards.each { |g| guard(**g, &g[:block]) }
  end
  # rubocop: enable Metrics/MethodLength

  module Patterns
    INTEGER = /\d+/
    FLOAT = /\d+\.?|\d*\.\d+/
    RATIONAL = %r{\d+/\d+}
    IPV4 = /[0-9.]{7,15}/
    IPV6 = /[:a-fA-F0-9\.]{2,45}/
    IPADDR = Regexp.union(IPV4, IPV6)
    IPV4_NET = %r{#{IPV4}/\d{1,2}}
    IPV6_NET = %r{#{IPV6}\/\d{1,3}}
    IPNETADDR = Regexp.union(IPV4_NET, IPV6_NET)
    TRUE = /y|yes|t|true|on/i
    FALSE = /n|no|f|false|off/i
    BOOLEAN = Regexp.union(TRUE, FALSE)
  end

  def value(id, re, &block)
    val = @values[id] = Value.new(id, re, &block)
    define_singleton_method(id) do
      @current_record_values << val
      "(?<#{id}>#{re.source})"
    end
  end

  def inline(id, &block)
    @values[id] = InlineValue.new(id, &block)
  end

  def boolean(id, re = Patterns::BOOLEAN)
    value(id, re) { |val| !val.match(Patterns::FALSE) }
  end

  def integer(id, re = Patterns::INTEGER)
    value(id, re) { |val| Integer(val) }
  end

  def float(id, re = Patterns::FLOAT)
    value(id, re) { |val| Float(val) }
  end

  def rational(id, re = Patterns::RATIONAL)
    value(id, re) { |val| Rational(val) }
  end

  def ipaddr(id, re = Patterns::IPADDR)
    value(id, re) { |val| IPAddr.new(val) }
  end

  def ipnetaddr(id, re = Patterns::IPNETADDR)
    value(id, re) { |val| IPAddr.new(val) }
  end

  def record(klass = Record, **kwargs, &block)
    raise "#{self.class}.record requires a block" unless block
    kwargs[:extractor_values] = values
    kwargs[:factory] ||= @factory if @factory
    kwargs[:values] = @current_record_values = []
    @records << klass.new(instance_exec(&block), **kwargs)
  end

  def section(delimiter, terminator = nil)
    @section_delimiter = delimiter
    @section_terminator = terminator
  end

  def factory(object = nil)
    if object
      @factory = object
    else
      @factory
    end
  end

  def filldown(**kwargs, &block)
    raise "#{self.class}.filldown requires a block" unless block
    record(Filldown, **kwargs, &block)
  end

  def find_record_for(match)
    records[records.length.times.find_index { |i| match["__#{i}"] }]
  end

  def guard(**kwargs, &block)
    raise "#{self.class}.guard requires a block" unless block
    record(Guard, **kwargs, &block)
  end

  def guards(*guard_args)
    guard_args = Guards::DEFAULT if guard_args.empty?
    @append_guards = guard_args
  end

  def scan(input)
    prefill = {}
    sections(input).flat_map { |section|
      Extraction.new(section, self, prefill).scan.extraction_matches
    }
  end

  def sections(input)
    return [input] unless @section_delimiter

    texts = input.split(@section_delimiter)
    return texts unless @section_terminator

    texts.map { |section| section + @section_terminator }
  end

  def skip(**kwargs, &block)
    raise "#{self.class}.skip requires a block" unless block
    record(Skip, **kwargs, &block)
  end

  def regexps
    @records.map.with_index do |record, i|
      Regexp.new("(?<__#{i}>#{record.source})", record.options)
    end
  end

  def to_re
    Regexp.union(*regexps)
  end
end # class TextExtractor
