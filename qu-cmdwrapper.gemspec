# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'qu/cmdwrapper/version'

Gem::Specification.new do |spec|
  spec.name          = "qu-cmdwrapper"
  spec.version       = Qu::Cmdwrapper::VERSION
  spec.authors       = ["Wubin Qu"]
  spec.email         = ["quwubin@gmail.com"]
  spec.description   = %q{A wrapper for command-line tools, mostly are bioinformatics related tools}
  spec.summary       = %q{A wrapper for command-line tools}
  spec.homepage      = "https://github.com/quwubin/qu-cmdwrapper"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'qu-utils', '~> 1.0'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rspec"
end
