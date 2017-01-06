# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pivotal_tracker_cli/version'

Gem::Specification.new do |spec|
  spec.name = 'pivotal_tracker_cli'
  spec.version = PivotalTrackerCli::VERSION
  spec.authors = ['Alex Hall']
  spec.email = ['me@jalexhall.com']

  spec.summary = 'This gem is supposed to be used for dev purposes'
  spec.description = 'Simple integration with pivotal-tracker gem'
  spec.homepage = 'http://github.com/alex-hall/pivotal_tracker_cli'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'httparty'
  spec.add_dependency 'thor'

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'awesome_print'
end
