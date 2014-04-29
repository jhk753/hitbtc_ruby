# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hitbtc/version'

Gem::Specification.new do |spec|
  spec.name          = "hitbtc"
  spec.version       = HitbtcRuby::VERSION
  spec.authors       = ["Julien Hobeika"]
  spec.email         = ["julien.hobeika@gmail.com"]
  spec.description   = %q{"Wrapper for hitbtc Exchange API"}
  spec.summary       = %q{"Wrapper for hitbtc Exchange API"}
  spec.homepage      = "https://github.com/jhk753/hitbtc_ruby"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_dependency "httparty"
  spec.add_dependency "hashie"
  spec.add_dependency "addressable"
end