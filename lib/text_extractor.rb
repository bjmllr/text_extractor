require_relative 'text_extractor/extraction'
require_relative 'text_extractor/filldown'
require_relative 'text_extractor/record'
require_relative 'text_extractor/value'

# represents an extractor definition
class TextExtractor
  attr_reader :records, :values

  def initialize(&block)
    raise "#{self.class}.new requires a block" unless block
    @values = {}
    @fill = {}
    @values = {}
    @records = []
    @filldowns = []
    @current_record_values = []
    instance_exec(&block)
  end

  module Patterns
    INTEGER = /\d+/
    FLOAT = /\d+\.?|\d*\.\d+/
    RATIONAL = %r{\d+/\d+}
    IPV4 = /[0-9.]{7,15}/
    IPV6 = /[:a-fA-F0-9\.]{2,45}/
    IPADDR = Regexp.union(IPV4, IPV6)
    IPV4_NET = /#{IPV4}\/\d{1,2}/
    IPV6_NET = /#{IPV6}\/\d{1,3}/
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

  def strip_record(regexp, strip: nil)
    lines = regexp.source.lines
    prefix = lines.last
    strip_record_by_line(lines, prefix, strip)
    Regexp.new(lines.join.strip, regexp.options)
  end

  def strip_record_by_line(lines, prefix, strip)
    return unless prefix =~ /\A\s*\z/

    lines.map! { |s| s.gsub(prefix.to_s, '') }
    case strip
    when :left  then lines.map! { |s| "\\s*#{s.lstrip}" }
    when :right then lines.map! { |s| "#{s.rstrip}\\s*" }
    when :both  then lines.map! { |s| "\\s*#{s.strip}\\s*" }
    end
  end

  def record(klass = Record, **kwargs, &block)
    raise "#{self.class}.record requires a block" unless block
    @current_record_values = []
    regexp = strip_record(instance_exec(&block), strip: kwargs.delete(:strip))
    kwargs[:values] = @current_record_values
    @records << klass.new(regexp, **kwargs)
  end

  def filldown(**kwargs, &block)
    raise "#{self.class}.filldown requires a block" unless block
    record(Filldown, **kwargs, &block)
  end

  def find_record_for(match)
    records[records.length.times.find_index { |i| match["__#{i}"] }]
  end

  def scan(input)
    Extraction.new(input, self).scan.extraction_matches
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
