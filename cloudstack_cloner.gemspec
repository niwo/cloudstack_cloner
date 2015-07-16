# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudstack_cloner/version'

Gem::Specification.new do |spec|
  spec.name          = "cloudstack_cloner"
  spec.version       = CloudstackCloner::VERSION
  spec.authors       = ["niwo"]
  spec.email         = ["nik.wolfgramm@gmail.com"]
  spec.summary       = %q{Automated CloudStack VM cloning}
  spec.description   = %q{Automated CloudStack VM cloning}
  spec.homepage      = "https://github.com/swisstxt/cloudstack_cloner"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency('thor', '~> 0.19.1')
  spec.add_dependency('cloudstack_client', '~> 1.0.4')
end
