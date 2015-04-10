require_relative "lib/text_extractor/version"

Gem::Specification.new do |s|
  s.name = 'text_extractor'
  s.version = TextExtractor.version
  s.platform = Gem::Platform::RUBY
  s.summary = "Easily extract data from text"
  s.description = s.summary
  s.author = "Ben Miller"
  s.email = "bjmllr@gmail.com"
  s.license = "MIT"
  s.required_ruby_version = ">= 2.0.0"
  s.files = Dir["lib/**/*.rb"]
  s.require_path = "lib"
end
