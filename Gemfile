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
    gem 'stackprof'
    gem 'sys-proctable'
    gem 'ruby-mass'
    gem 'benchmark-ips'
end

gem 'awesome_print'

gemspec

# gem 'ethon', github: 'zapotek/ethon', branch: 'optional-escaping'
# gem 'typhoeus', github: 'zapotek/typhoeus', branch: 'object-allocation-optimization'
gem 'ethon', path: '../ethon'
gem 'typhoeus', path: '../typhoeus'

gem 'arachni-reactor', github: 'arachni/arachni-reactor', branch: 'slice-to-byteslice'
