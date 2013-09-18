# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'itagami/version'

Gem::Specification.new do |spec|
  spec.name          = "itagami"
  spec.version       = Itagami::VERSION
  spec.authors       = ["Yoshinori SHIMADA"]
  spec.email         = ["simd.nyan@gmail.com"]
  spec.description   = %q{itagami is a Rakuten Securities client library for algorithmic trading.}
  spec.summary       = %q{Rakuten Securities client library}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "mechanize"
  spec.add_dependency "pit"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
