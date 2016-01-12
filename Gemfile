source 'https://rubygems.org'

gem 'rake'

group :docs do
    gem 'yard'
    gem 'redcarpet'
end

group :spec do
    gem 'simplecov', require: false, group: :test

    gem 'rspec', '2.99.0'
    gem 'faker'
end

group :prof do
    gem 'stackprof'
    gem 'sys-proctable'
    gem 'ruby-mass'
    gem 'benchmark-ips'
end

if !Gem.win_platform?
    gem 'ffi', github: 'ffi/ffi', branch: 'elcapt'
end

gem 'arachni-reactor', github: 'arachni/arachni-reactor', branch: 'slice-to-byteslice'

gemspec
