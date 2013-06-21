# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mongomapper_fallback/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Marcelo Correia Pinheiro"]
  gem.email         = ["salizzar@gmail.com"]
  gem.description   = %q{MongoMapper replicaset fallback mechanism}
  gem.summary       = %q{MongoMapperFallback is a simple mechanism to handle common replicaset connection failures.}
  gem.homepage      = "https://github.com/salizzar/mongomapper_fallback"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "mongomapper_fallback"
  gem.require_paths = ["lib"]
  gem.version       = MongomapperFallback::VERSION

  gem.add_development_dependency  'rspec'
  gem.add_development_dependency  'bson_ext'
  gem.add_development_dependency  'debugger'

  gem.add_runtime_dependency      'mongo_mapper'
end
