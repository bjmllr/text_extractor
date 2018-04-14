require File.expand_path('lib/text_extractor/version', __dir__)

Gem::Specification.new do |spec|
  spec.name = 'text_extractor'
  spec.version = TextExtractor.version
  spec.platform = Gem::Platform::RUBY
  spec.summary = 'Easily extract data from text'
  spec.author = 'Ben Miller'
  spec.email = 'bjmllr@gmail.com'
  spec.homepage = 'https://github.com/bjmllr/text_extractor'
  spec.license = 'GPL-3.0'
  spec.required_ruby_version = '>= 2.1.0'
  spec.files = Dir['lib/**/*.rb']
  spec.require_path = 'lib'

  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop', '~> 0.54'
end
