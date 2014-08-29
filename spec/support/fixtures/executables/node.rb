require Options.paths.root + 'ui/cli/output'
require Options.paths.lib  + 'rpc/server/dispatcher'
require Options.paths.lib  + 'processes/manager'

class Node < Arachni::RPC::Server::Dispatcher::Node

    def initialize
        super Options

        methods.each do |m|
            next if method( m ).owner != Arachni::RPC::Server::Dispatcher::Node
            self.class.send :private, m
            self.class.send :public, m
        end

        @server = Arachni::RPC::Server::Base.new( @options )
        @server.add_async_check do |method|
            # methods that expect a block are async
            method.parameters.flatten.include?( :block )
        end
        @server.add_handler( 'node', self )
        @server.start
    end

    def url
        "#{@options.rpc.server_address}:#{@options.rpc.server_port}"
    end

    def shutdown
        Reactor.global.delay 1 do
            Arachni::Processes::Manager.kill Process.pid
        end
    end

    def connect_to_peer( url )
        self.class.connect_to_peer( url, @options )
    end

    def self.connect_to_peer( url, opts )
        c = Arachni::RPC::Client::Base.new( opts, url )
        Arachni::RPC::Proxy.new( c, 'node' )
    end
end

Reactor.global.run do
    Node.new
end
