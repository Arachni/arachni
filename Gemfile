source 'https://rubygems.org'

gem 'rake'
gem 'pry'

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
    gem 'memory_profiler'
end

gem 'arachni-rpc',     github: 'Arachni/arachni-rpc'
gem 'arachni-reactor', github: 'Arachni/arachni-reactor'

gemspec
