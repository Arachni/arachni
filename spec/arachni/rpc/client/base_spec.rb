require_relative '../../../spec_helper'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/base'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/base'

require 'ostruct'

class Server
    def initialize( opts, &block )
        @opts = opts
        @opts.rpc_address = 'localhost'
        @server = Arachni::RPC::Server::Base.new( @opts )
        @server.add_handler( "foo", self )

        if block_given?
            start
            block.call self
            shutdown
        end
    end

    def url
        "#{@opts.rpc_address}:#{@opts.rpc_port}"
    end

    def start
        t = Thread.new { @server.run }
        sleep( 0.1 ) while !@server.ready?
    end

    def shutdown
        while ::EM.reactor_running?
            ::EM.stop
            sleep( 0.1 )
        end
    end

    def bar
        true
    end
end

describe Arachni::RPC::Client::Base do
    before( :all ) do
        @client_class = Arachni::RPC::Client::Base
    end

    describe :new do
        context 'without SSL options' do
            it 'should connect succesfully to a server' do
                opts = OpenStruct.new
                opts.rpc_port = 9990

                Server.new( opts ) do |server|
                    client = @client_class.new( opts, server.url )
                    client.call( "foo.bar" ).should be_true
                end
            end
        end

        context 'with valid SSL options' do
            it 'should connect succesfully to an SSL server' do
                opts = OpenStruct.new
                opts.rpc_port = 9991

                opts.ca = spec_path + 'pems/cacert.pem'
                opts.node_ssl_pkey = spec_path + 'pems/client/key.pem'
                opts.node_ssl_cert = spec_path + 'pems/client/cert.pem'
                opts.ssl_pkey = spec_path + 'pems/server/key.pem'
                opts.ssl_cert = spec_path + 'pems/server/cert.pem'

                Server.new( opts ) do |server|
                    client = @client_class.new( opts, server.url )
                    client.call( "foo.bar" ).should be_true
                end
            end
        end

        context 'with invalid SSL options' do
            it 'should be unable to connect to an SSL server' do
                opts = OpenStruct.new
                opts.rpc_port = 9992

                opts.ssl_ca = spec_path + 'pems/cacert.pem'
                opts.node_ssl_pkey = spec_path + 'pems/client/foo-key.pem'
                opts.node_ssl_cert = spec_path + 'pems/client/foo-cert.pem'
                opts.ssl_pkey = spec_path + 'pems/server/key.pem'
                opts.ssl_cert = spec_path + 'pems/server/cert.pem'

                Server.new( opts ) do |server|
                    raised = false
                    begin
                        client = @client_class.new( opts, server.url )
                        client.call( "foo.bar" )
                    rescue Arachni::RPC::Exceptions::ConnectionError
                        raised = true
                    end

                    raised.should be_true
                end
            end
        end

        context 'with no SSL options' do
            it 'should be unable to connect to an SSL server' do
                opts = OpenStruct.new
                opts.rpc_port = 9993

                opts.ssl_ca = spec_path + 'pems/cacert.pem'
                opts.ssl_pkey = spec_path + 'pems/server/key.pem'
                opts.ssl_cert = spec_path + 'pems/server/cert.pem'

                Server.new( opts ) do |server|
                    raised = false
                    begin
                        client = @client_class.new( OpenStruct.new, server.url )
                        client.call( "foo.bar" )
                    rescue Arachni::RPC::Exceptions::SSLPeerVerificationFailed
                        raised = true
                    end

                    raised.should be_true
                end
            end
        end

    end

end
