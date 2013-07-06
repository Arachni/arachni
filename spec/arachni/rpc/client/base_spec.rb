require 'spec_helper'

class Server
    def initialize( opts, token = nil, &block )
        @opts = opts
        @server = Arachni::RPC::Server::Base.new( @opts, token )
        @server.add_handler( "foo", self )

        if block_given?
            start
            block.call self
            process_kill_em
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
        @opts.rpc_address = Arachni::Options.rpc_address.dup
        @client_class = Arachni::RPC::Client::Base
    end

    describe '.new' do
        context 'without SSL options' do
            it 'connects to a server' do
                opts = @opts.dup
                opts.rpc_port = available_port
                Server.new( opts ) do |server|
                    client = @client_class.new( opts, server.url )
                    client.call( "foo.bar" ).should == true
                end
            end
        end

        context 'when trying to connect to an SSL-enabled server' do
            context 'with valid SSL options' do
                it 'connects successfully' do
                    opts = @opts.dup
                    opts.rpc_port = available_port

                    opts.ca = support_path + 'pems/cacert.pem'
                    opts.node_ssl_pkey = support_path + 'pems/client/key.pem'
                    opts.node_ssl_cert = support_path + 'pems/client/cert.pem'
                    opts.ssl_pkey = support_path + 'pems/server/key.pem'
                    opts.ssl_cert = support_path + 'pems/server/cert.pem'

                    Server.new( opts ) do |server|
                        client = @client_class.new( opts, server.url )
                        client.call( "foo.bar" ).should be_true
                    end
                end
            end

            context 'with invalid SSL options' do
                it 'throws an exception' do
                    opts = @opts.dup
                    opts.rpc_port = available_port

                    opts.ssl_ca = support_path + 'pems/cacert.pem'
                    opts.node_ssl_pkey = support_path + 'pems/client/foo-key.pem'
                    opts.node_ssl_cert = support_path + 'pems/client/foo-cert.pem'
                    opts.ssl_pkey = support_path + 'pems/server/key.pem'
                    opts.ssl_cert = support_path + 'pems/server/cert.pem'

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
                it 'throws an exception' do
                    opts = @opts.dup
                    opts.rpc_port = available_port

                    opts.ssl_ca = support_path + 'pems/cacert.pem'
                    opts.ssl_pkey = support_path + 'pems/server/key.pem'
                    opts.ssl_cert = support_path + 'pems/server/cert.pem'

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

        context 'when a server requires a token' do
            context 'with a valid token' do
                it 'connects successfully' do
                    opts = @opts.dup
                    opts.rpc_port = available_port
                    token = 'secret!'

                    Server.new( opts, token ) do |server|
                        client = @client_class.new( opts, server.url, token )
                        client.call( "foo.bar" ).should be_true
                    end
                end
            end
            context 'with invalid token' do
                it 'throws an exception' do
                    opts = @opts.dup
                    opts.rpc_port = available_port
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
