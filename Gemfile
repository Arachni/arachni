source 'http://rubygems.org'

gem 'yard'
gem 'redcarpet'

gem 'faker'

gem 'ethon', git: 'https://github.com/typhoeus/ethon.git'

if File.exist?( p = File.dirname( __FILE__ ) + '/../arachni-rpc-em' )
    gem 'arachni-rpc-em', path: p
else
    gem 'arachni-rpc-em', git: 'http://github.com/Arachni/arachni-rpc-em.git'
end

gemspec
