source 'https://rubygems.org'

gem 'rake'

group :docs do
    gem 'yard'
    gem 'redcarpet'
end

group :spec do
    gem 'simplecov', require: false, group: :test

    gem 'rspec'
    gem 'faker'

    gem 'puma' if !Gem.win_platform? || RUBY_PLATFORM == 'java'

    gem 'sinatra'
    gem 'sinatra-contrib'
end

group :prof do
    gem 'benchmark-ips'
    gem 'stackprof'
    gem 'sys-proctable'
    gem 'ruby-mass'
    gem 'benchmark-ips'
end

gemspec

gem 'arachni-reactor', path: '../arachni-reactor/'
