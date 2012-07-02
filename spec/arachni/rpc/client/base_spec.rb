require_relative '../../../spec_helper'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/base'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/base'

require 'ostruct'

class Server
    def initialize( opts, token = nil, &block )
        @opts = opts
        @server = Arachni::RPC::Server::Base.new( @opts, token )
        @server.add_handler( "foo", self )

        if block_given?
            start
            block.call self
            kill_em
        end
    end

    def url
        "#{@opts.rpc_address}:#{@opts.rpc_port}"
    end

    def start
        t = Thread.new { @server.run }
        sleep( 0.1 ) while !@server.ready?
    end

    def bar
        true
    end
end

describe Arachni::RPC::Client::Base do
    before( :all ) do
        @opts = OpenStruct.new
        @opts.rpc_address = Arachni::Options.instance.rpc_address.dup
        @client_class = Arachni::RPC::Client::Base
    end

    describe '.new' do
        context 'without SSL options' do
            it 'should connect successfully to a server' do
                opts = @opts.dup
                opts.rpc_port = random_port
                Server.new( opts ) do |server|
                    client = @client_class.new( opts, server.url )
                    client.call( "foo.bar" ).should == true
                end
            end
        end

        context 'with valid SSL options' do
            it 'should connect successfully to an SSL server' do
                opts = @opts.dup
                opts.rpc_port = random_port

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
                opts = @opts.dup
                opts.rpc_port = random_port

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
                opts = @opts.dup
                opts.rpc_port = random_port

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

        context 'when a server requires a token' do
            context 'with a valid token' do
                it 'should be able to connect' do
                    opts = @opts.dup
                    opts.rpc_port = random_port
                    token = 'secret!'

                    Server.new( opts, token ) do |server|
                        client = @client_class.new( opts, server.url, token )
                        client.call( "foo.bar" ).should be_true
                    end
                end
            end
            context 'with invalid token' do
                it 'should not be able to connect' do
                    opts = @opts.dup
                    opts.rpc_port = random_port
                    token = 'secret!'

                    Server.new( opts, token ) do |server|
                        raised = false
                        begin
                            client = @client_class.new( OpenStruct.new, server.url )
                            client.call( "foo.bar" )
                        rescue Arachni::RPC::Exceptions::InvalidToken
                            raised = true
                        end

                        raised.should be_true
                    end
                end
            end
        end


    end

end
