require_relative "text_extractor/extraction"

# represents an extractor definition
class TextExtractor
  def initialize(&block)
    fail "#{self.class}.new requires a block" unless block
    @values = {}
    @records = []
    instance_exec(&block)
  end

  def value(id, re)
    define_singleton_method(id) { "(?<#{id}>#{re.source})" }
  end

  def strip_record(regexp)
    lines = regexp.source.lines
    prefix = lines.last
    lines.map! { |s| s.gsub("#{prefix}", "") }
    Regexp.new(lines.join.strip)
  end

  def record(&block)
    fail "#{self.class}.record requires a block" unless block
    @records << strip_record(instance_exec(&block))
  end

  def scan(input)
    Extraction.new(input, to_re).scan.record_matches
  end

  def regexps
    @records.map { |record| Regexp.new(record.source, Regexp::MULTILINE) }
  end

  def to_re
    Regexp.union(*regexps)
  end
end # class TextScan
