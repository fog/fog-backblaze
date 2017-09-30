# coding: utf-8

require_relative 'lib/fog/backblaze/version'

Gem::Specification.new do |spec|
  spec.name          = "fog-backblaze"
  spec.version       = Fog::Backblaze::VERSION
  spec.authors       = ["Pavel Evstigneev"]
  spec.email         = ["pavel.evst@gmail.com"]

  spec.summary       = %q{Write a short summary, because Rubygems requires one.}
  spec.description   = %q{Write a longer description or delete this line.}
  #spec.homepage      = "Put your gem's website or public repo URL here."

  #if spec.respond_to?(:metadata)
  #  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  #else
  #  raise "RubyGems 2.0 or newer is required to protect against " \
  #    "public gem pushes."
  #end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "fog-core"
end
