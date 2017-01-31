=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

require Options.paths.lib + 'rpc/client/base'

module RPC
class Client

# RPC Dispatcher client
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Dispatcher

    attr_reader :node

    def initialize( opts, url )
        @client = Base.new( opts, url )
        @node   = Proxy.new( @client, 'node' )

        # map Dispatcher handlers
        Dir.glob( "#{Options.paths.services}*.rb" ).each do |handler|
            name = File.basename( handler, '.rb' )

            self.class.send( :attr_reader, name.to_sym )
            instance_variable_set( "@#{name}".to_sym, Proxy.new( @client, name ) )
        end
    end

    def url
        @client.url
    end

    def close
        @client.close
    end

    private

    # Used to provide the illusion of locality for remote methods
    def method_missing( sym, *args, &block )
        @client.call( "dispatcher.#{sym.to_s}", *args, &block )
    end

end

end
end
end
