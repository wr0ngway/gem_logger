# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gem_logger/version'

Gem::Specification.new do |spec|
  spec.name          = "gem_logger"
  spec.version       = GemLogger::VERSION
  spec.authors       = ["Matt Conway"]
  spec.email         = ["matt@conwaysplace.com"]
  spec.description   = %q{Allows classes/modules in gems to have logger class/instance methods with a pluggable Logger implementation}
  spec.summary       = %q{Allows classes/modules in gems to have logger class/instance methods with a pluggable Logger implementation}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest_should"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "factory_girl"
  spec.add_development_dependency "faker"

  spec.add_dependency "activesupport"
end
