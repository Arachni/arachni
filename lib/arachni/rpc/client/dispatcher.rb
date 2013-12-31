=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require Options.paths.lib + 'rpc/client/base'

module RPC
class Client

#
# RPC Dispatcher client
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Dispatcher

    attr_reader :node

    def initialize( opts, url )
        @client = Base.new( opts, url )
        @node = RemoteObjectMapper.new( @client, 'node' )

        # map Dispatcher handlers
        Dir.glob( "#{Options.paths.rpcd_handlers}*.rb" ).each do |handler|
            name = File.basename( handler, '.rb' )

            self.class.send( :attr_reader, name.to_sym )
            instance_variable_set( "@#{name}".to_sym, RemoteObjectMapper.new( @client, name ) )
        end
    end

    def url
        @client.url
    end

    def close
        @client.close
    end

    private

    #
    # Used to provide the illusion of locality for remote methods
    #
    def method_missing( sym, *args, &block )
        @client.call( "dispatcher.#{sym.to_s}", *args, &block )
    end

end

end
end
end
