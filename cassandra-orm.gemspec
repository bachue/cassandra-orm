# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cassandra-orm/version'

Gem::Specification.new do |spec|
  spec.name          = 'cassandra-orm'
  spec.version       = CassandraORM::VERSION
  spec.authors       = ['Bachue Zhou']
  spec.email         = ['bachue.shu@gmail.com']

  spec.summary       = 'Just a simple orm library for Cassandra, based on cassandra-driver, support i18n & async.'
  spec.description   = spec.summary

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.test_files    = Dir['spec/*_spec.rb']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.2.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0.0'
  spec.add_dependency 'cassandra-driver'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'i18n'
end
