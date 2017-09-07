# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kitchen-vmpool/version'

Gem::Specification.new do |spec|
  spec.name          = "kitchen-vmpool"
  spec.version       = KitchenVmpool::VERSION
  spec.authors       = ["Corey Osman"]
  spec.email         = ["corey@nwops.io"]

  spec.summary       = %q{Test Kitchen driver for virtual machine pools}
  spec.description   = %q{When you need to create pools of vms and manage them with test kitchen}
  spec.homepage      = "https://gitlab.com/nwops/kitchen-vmpool"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "gitlab", "~> 4.2"
  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
