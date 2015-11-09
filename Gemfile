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
end

group :prof do
    gem 'stackprof'
    gem 'sys-proctable'
    gem 'ruby-mass'
    gem 'benchmark-ips'
end

# gem 'ffi',      github: 'ffi/ffi', branch: 'elcapt'
gem 'ethon',    github: 'typhoeus/ethon'
gem 'typhoeus', github: 'typhoeus/typhoeus'

gem 'arachni-reactor', github: 'arachni/arachni-reactor', branch: 'slice-to-byteslice'

gemspec
