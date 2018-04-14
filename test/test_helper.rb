require 'minitest/autorun'
$LOAD_PATH << File.expand_path('../lib', __dir__)

def unindent(string)
  string.gsub(/^#{string.scan(/^[ \t]+(?=\S)/).min}/, '')
end
