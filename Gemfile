source 'http://rubygems.org'

gem 'rake'

group :docs do
    gem 'yard'
    gem 'redcarpet'
end

group :spec do
    gem 'simplecov', require: false, group: :test

    gem 'rspec', '2.99'
    gem 'faker'

    gem 'puma' if !Gem.win_platform? || RUBY_PLATFORM == 'java'

    gem 'sinatra'
    gem 'sinatra-contrib'
end

group :prof do
    gem 'stackprof'
end

gem 'typhoeus', github: 'typhoeus/typhoeus'
gem 'ethon',    github: 'typhoeus/ethon'

gem 'arachni-reactor', path: '../arachni-reactor'
gem 'arachni-rpc',     path: '../arachni-rpc-v0.2'

gemspec
