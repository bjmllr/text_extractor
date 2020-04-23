require_relative 'text_extractor/extraction'
require_relative 'text_extractor/filldown'
require_relative 'text_extractor/guard'
require_relative 'text_extractor/record'
require_relative 'text_extractor/skip'
require_relative 'text_extractor/value'
require_relative 'text_extractor/inline_value'

# represents an extractor definition
class TextExtractor
  @append_newline = false

  singleton_class.instance_eval do
    attr_accessor :append_newline
  end

  attr_reader :records, :values

  def initialize(&block)
    raise "#{self.class}.new requires a block" unless block

    initialize_options
    initialize_collections
    instance_exec(&block)
    @append_guards.each { |g| guard(**g, &g[:block]) }
  end

  def initialize_options
    @factory = nil
    @section_delimiter = nil
    @section_terminator = nil
    @strip = nil
    @append_newline = nil
  end

  def initialize_collections
    @values = {}
    @fill = {}
    @values = {}
    @records = []
    @filldowns = []
    @current_record_values = []
    @append_guards = []
  end

  module Patterns
    INTEGER = /\d+/.freeze
    FLOAT = /\d+\.?|\d*\.\d+/.freeze
    RATIONAL = %r{\d+/\d+}.freeze
    IPV4 = /[0-9.]{7,15}/.freeze
    IPV6 = /[:a-fA-F0-9\.]{2,45}/.freeze
    IPADDR = Regexp.union(IPV4, IPV6)
    IPV4_NET = %r{#{IPV4}/\d{1,2}}.freeze
    IPV6_NET = %r{#{IPV6}\/\d{1,3}}.freeze
    IPNETADDR = Regexp.union(IPV4_NET, IPV6_NET)
    TRUE = /y|yes|t|true|on/i.freeze
    FALSE = /n|no|f|false|off/i.freeze
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

  def append_newline(activate = nil)
    return TextExtractor.append_newline if activate.nil? && @append_newline.nil?
    return @append_newline if activate.nil?

    @append_newline = activate
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

  STRIP_PROCS = {
    left: ->(s) { s.split("\n").map(&:lstrip).join("\n") + "\n" },
    right: ->(s) { s.split("\n").map(&:rstrip).join("\n") + "\n" },
    both: ->(s) { s.split("\n").map(&:strip).join("\n") + "\n" }
  }.freeze

  def strip(side = nil)
    @strip = STRIP_PROCS[side] ||
             (raise ArgumentError, 'Unknown strip option')
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
    guard_args = Guard::DEFAULT if guard_args.empty?
    @append_guards = guard_args
  end

  def scan(input)
    input = @strip.call(input) if @strip
    input += "\n" if append_newline && !input.end_with?("\n")
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
