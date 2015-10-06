require_relative "text_extractor/extraction"
require_relative "text_extractor/record"

# represents an extractor definition
class TextExtractor
  attr_reader :converters, :records

  def initialize(&block)
    fail "#{self.class}.new requires a block" unless block
    @converters = {}
    @records = []
    instance_exec(&block)
  end

  module Patterns
    INTEGER = /\d+/
    FLOAT = /\d+\.?|\d*\.\d+/
    RATIONAL = %r(\d+/\d+)
    IPV4 = /[0-9.]{7,15}/
    IPV6 = /[:a-fA-F0-9\.]{2,45}/
    IPADDR = Regexp.union(IPV4, IPV6)
    TRUE = /y|yes|t|true|on/i
    FALSE = /n|no|f|false|off/i
    BOOLEAN = Regexp.union(TRUE, FALSE)
  end

  def value(id, re, &block)
    @converters[id] = block if block_given?
    define_singleton_method(id) { "(?<#{id}>#{re.source})" }
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

  def strip_record(regexp)
    lines = regexp.source.lines
    prefix = lines.last
    lines.map! { |s| s.gsub("#{prefix}", "") } if prefix =~ /\A\s*\z/
    Regexp.new(lines.join.strip)
  end

  def record(factory = nil, &block)
    fail "#{self.class}.record requires a block" unless block
    @records << Record.new(strip_record(instance_exec(&block)), factory)
  end

  def find_factory_for(match)
    return if no_factory?
    return single_factory if single_factory
    records[records.length.times.find_index { |i| match["__#{i}"] }].factory
  end

  def no_factory?
    return @no_factory unless @no_factory.nil?
    @no_factory = records.none?(&:factory)
  end

  def single_factory
    return @single_factory unless @single_factory.nil?
    @single_factory = records.all?(&:factory) &&
                      records.map(&:factory).uniq.length == 1 &&
                      records.first.factory
  end

  def scan(input)
    Extraction.new(input, self).scan.record_matches
  end

  def regexps
    @records.map.with_index do |record, i|
      Regexp.new("(?<__#{i}>#{record.source})", Regexp::MULTILINE)
    end
  end

  def to_re
    Regexp.union(*regexps)
  end
end # class TextExtractor
