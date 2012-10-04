# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'switcheroo/version'

Gem::Specification.new do |gem|
  gem.name          = 'switcheroo'
  gem.version       = Switcheroo::VERSION
  gem.authors       = ['JohnnyT']
  gem.email         = ['johnnyt@moneydesktop.com']
  gem.description   = %q{ActiveRecord migration library to speed up schema changes for large PostgreSQL tables}
  gem.summary       = gem.description
  gem.homepage      = 'https://github.com/moneydesktop/switcheroo'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'rake'
end
