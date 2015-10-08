require "minitest/autorun"
$LOAD_PATH << File.expand_path("../lib", __dir__)

def unindent(s)
  s.gsub(/^#{s.scan(/^[ \t]+(?=\S)/).min}/, "")
end
