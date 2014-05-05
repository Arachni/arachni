source 'http://rubygems.org'

gem 'rake'

group :docs do
    gem 'yard'
    gem 'redcarpet'
end

group :spec do
    gem 'rspec'
    gem 'faker'

    gem 'thin' if !Gem.win_platform?

    gem 'sinatra'
    gem 'sinatra-contrib'
end

group :prof do
    gem 'stackprof'
end

gem 'ethon', path: File.dirname( __FILE__ ) + '/../ethon'

gem 'arachni-reactor', path: File.dirname( __FILE__ ) + '/../arachni-reactor'
gem 'arachni-rpc',     path: File.dirname( __FILE__ ) + '/../arachni-rpc-v0.2'

gemspec
