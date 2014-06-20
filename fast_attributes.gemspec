# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fast_attributes/version'

Gem::Specification.new do |spec|
  spec.name          = 'fast_attributes'
  spec.version       = FastAttributes::VERSION
  spec.authors       = ['Kostiantyn Stepaniuk']
  spec.email         = ['ks@applift.com']
  spec.summary       = 'Fast attributes with data types'
  spec.description   = 'Fast attributes with data types'
  spec.homepage      = 'https://github.com/applift/fast_attributes'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
end
