require 'strscan'

require 'text_extractor/directives/classes'
require 'text_extractor/directives/group'

class TextExtractor
  def self.expand_directives(re)
    Directives.new(re).expand
  end

  # Directives can only be named with lowercase ascii letters (a-z) and _
  # (underscore).
  #
  # Directives can take an argument. An argument can contain any sequence of
  # characters other than newlines, parenthesis, or dot (.). The argument
  # appears after the name, in parenthesis, with no whitespace between the name
  # and left parenthesis. Whitespace inside the parenthesis is taken literally
  # and not ignored.
  #
  # When used, each directive name is preceeded by a dot (.). There should be no
  # whitespace on either side of the dot. Some directives can be chained one
  # after another, still using a dot to separate the earlier directive from the
  # later one.
  class Directives
    def initialize(original)
      @source = original.source
      @options = original.options
    end

    def expand
      return @output if @output
      @state = State.new
      scanner = StringScanner.new(@source)
      read_line(scanner) until scanner.eos?
      raise 'Unterminated line group' unless @state.groups.empty?
      @output = Regexp.new(@state.target.join(''), @options)
    end

    private

    DIRECTIVE_MAP = {
      ' '      => { class: Comment },
      'any'    => { class: Any },
      'begin'  => { class: Begin, arguments: :parsed },
      'end'    => { class: End },
      'maybe'  => { class: Maybe },
      'repeat' => { class: Repeat, arguments: :parse },
      'rest'   => { class: Rest }
    }.freeze
    private_constant :DIRECTIVE_MAP

    def read_line(scanner)
      line = scanner.scan_until(/\n/)

      unless line
        line = scanner.rest
        scanner.skip(/.*/)
      end

      @state.current = @state.current_line = line
      add_line
    end

    def add_line
      apply_directives read_directives
      return unless @state.current

      if @state.groups.empty?
        @state.target << @state.current
      else
        @state.groups.last << @state.current
      end
    end

    def read_directives
      md = @state.current_line.match(/(^| )#\./)

      if md
        @state.current = md.pre_match
        @state.current += "\n" if @state.newline?
        parse_directives(md.post_match.rstrip)
      else
        []
      end
    end

    def apply_directives(directives)
      directives.each(&:call)
    end

    def parse_directives(full_source)
      return [Comment.new(@state)] if full_source.start_with?(' ')
      split_directives(full_source)
        .map { |source| parse_one_directive(source) }
    end

    def parse_one_directive(source)
      md = source.match(/^[a-z_]+/) || source.match(/^ /)
      raise "Unknown directive(s) in #{@state.current_line}" unless md
      word = md[0]
      map = DIRECTIVE_MAP.fetch(word) { raise "Unknown directive #{word}" }
      args = parse_arguments(map[:arguments], md.post_match)
      map.fetch(:class).new(@state, *args)
    end

    def split_directives(source)
      source.split('.')
    end

    def parse_arguments(rule, source)
      return [] unless rule
      return rule.call(source) if rule.is_a?(Proc)
      source.match(/\(([^)]*)\)/) { |md| md[1] }
    end
  end # class Expander

  State = Struct.new(:current, :current_line, :groups, :target) do
    def initialize(*)
      super
      self.groups ||= []
      self.target ||= []
    end

    def last_group
      groups.last
    end

    def newline?
      current_line.end_with?("\n")
    end
  end # module Directives
end # class TextExtractor
