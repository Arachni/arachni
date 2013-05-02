source 'http://rubygems.org'

gem 'yard'
gem 'redcarpet'

# The Arachni Framework.
if File.exist?( p = File.dirname( __FILE__ ) + '/../arachni-rpc-em' )
    gem 'arachni-rpc-em', path: p
else
    gem 'arachni-rpc-em', '0.1.4dev', git: 'git://github.com/Arachni/arachni-rpc-em.git'
end

gemspec
