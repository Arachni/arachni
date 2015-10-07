require 'spec_helper'
require "#{Arachni::Options.paths.lib}/rpc/server/base"

class Server
    def initialize( opts, token = nil, &block )
        @opts = opts
        @server = Arachni::RPC::Server::Base.new( @opts, token )
        @server.add_handler( "foo", self )

        if block_given?
            start
            block.call self
            process_kill_reactor
        end
    end

    def url
        "#{@opts.rpc.server_address}:#{@opts.rpc.server_port}"
    end

    def start
        Arachni::Reactor.global.run_in_thread if !Arachni::Reactor.global.running?
        @server.start
        sleep( 0.1 ) while !@server.ready?
    end

    def bar
        true
    end
end

describe Arachni::RPC::Client::Base do
    let(:empty_options) do
        OpenStruct.new( rpc: OpenStruct.new )
    end

    let(:options) do
        empty_options.rpc.server_address = Arachni::Options.rpc.server_address
        empty_options.rpc.server_port    = available_port
        empty_options
    end

    let(:ssl_options) do
        options.rpc.ssl_ca = support_path + 'pems/cacert.pem'
        options.rpc.client_ssl_private_key = support_path + 'pems/client/key.pem'
        options.rpc.client_ssl_certificate = support_path + 'pems/client/cert.pem'
        options.rpc.server_ssl_private_key = support_path + 'pems/server/key.pem'
        options.rpc.server_ssl_certificate = support_path + 'pems/server/cert.pem'
        options
    end

    describe '.new' do
        context 'without SSL options' do
            it 'connects to a server' do
                Server.new( options ) do |server|
                    client = described_class.new( options, server.url )
                    expect(client.call( "foo.bar" )).to eq(true)
                end
            end
        end

        context 'when trying to connect to an SSL-enabled server' do
            context 'with valid SSL options' do
                it 'connects successfully' do
                    Server.new( ssl_options ) do |server|
                        client = described_class.new( ssl_options, server.url )
                        expect(client.call( "foo.bar" )).to be_truthy
                    end
                end
            end

            context 'with invalid SSL options' do
                it 'throws an exception' do
                    ssl_options.rpc.client_ssl_private_key = nil
                    ssl_options.rpc.client_ssl_certificate = nil

                    Server.new( ssl_options ) do |server|
                        raised = false
                        begin
                            client = described_class.new( ssl_options, server.url )
                            client.call( "foo.bar" )
                        rescue Arachni::RPC::Exceptions::ConnectionError
                            raised = true
                        end

                        expect(raised).to be_truthy
                    end
                end
            end

            context 'with no SSL options' do
                it 'throws an exception' do
                    opts = options.dup
                    opts.rpc.server_port = available_port

                    opts.rpc.ssl_ca = support_path + 'pems/cacert.pem'
                    opts.rpc.server_ssl_private_key = support_path + 'pems/server/key.pem'
                    opts.rpc.server_ssl_certificate = support_path + 'pems/server/cert.pem'

                    Server.new( opts ) do |server|
                        raised = false
                        begin
                            client = described_class.new( empty_options, server.url )
                            client.call( "foo.bar" )
                        rescue Arachni::RPC::Exceptions::ConnectionError
                            raised = true
                        end

                        expect(raised).to be_truthy
                    end
                end
            end
        end

        context 'when a server requires a token' do
            context 'with a valid token' do
                it 'connects successfully' do
                    opts = options.dup
                    opts.rpc.server_port = available_port
                    token = 'secret!'

                    Server.new( opts, token ) do |server|
                        client = described_class.new( opts, server.url, token )
                        expect(client.call( "foo.bar" )).to be_truthy
                    end
                end
            end
            context 'with invalid token' do
                it 'throws an exception' do
                    opts = options.dup
                    opts.rpc.server_port = available_port
                    token = 'secret!'

                    Server.new( opts, token ) do |server|
                        raised = false
                        begin
                            client = described_class.new( empty_options, server.url )
                            client.call( "foo.bar" )
                        rescue Arachni::RPC::Exceptions::InvalidToken
                            raised = true
                        end

                        expect(raised).to be_truthy
                    end
                end
            end
        end

    end

end
