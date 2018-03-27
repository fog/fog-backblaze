# coding: utf-8

require_relative 'lib/fog/backblaze/version'

Gem::Specification.new do |spec|
  spec.name          = "fog-backblaze"
  spec.version       = Fog::Backblaze::VERSION
  spec.authors       = ["Pavel Evstigneev"]
  spec.email         = ["pavel.evst@gmail.com"]

  spec.summary       = "Module for the 'fog' gem to support Blackblade B2 stogate."
  spec.description   = "Blackblade B2 stogate client for 'fog' gem, can be used for working with files and buckets. E.g. carrierwave uploads"
  spec.homepage      = "https://github.com/fog/fog-backblaze"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "fog-core", ">= 1.40", "<3"
end
