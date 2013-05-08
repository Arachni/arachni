source 'http://rubygems.org'

gem 'yard'
gem 'redcarpet'

# The Arachni Framework.
if File.exist?( p = File.dirname( __FILE__ ) + '/../arachni-rpc-em' )
    gem 'arachni-rpc-em', path: p
else
    gem 'arachni-rpc-em', github: 'Arachni/arachni-rpc-em', branch: 'experimental'
end

gemspec
