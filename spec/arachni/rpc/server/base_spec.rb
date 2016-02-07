require 'spec_helper'
require "#{Arachni::Options.paths.lib}/rpc/server/base"

describe Arachni::RPC::Server::Base do
    before( :all ) do
        opts = Arachni::Options.instance
        opts.rpc.server_port = available_port

        Arachni::Reactor.global.run_in_thread if !Arachni::Reactor.global.running?

        @server = Arachni::RPC::Server::Base.new( opts )
    end

    it 'supports UNIX sockets', if: Arachni::Reactor.supports_unix_sockets? do
        opts = Arachni::Options.instance
        opts.rpc.server_address = nil
        opts.rpc.server_port    = nil
        opts.rpc.server_socket  = "#{Dir.tmpdir}/arachni-base-#{Arachni::Utilities.generate_token}"
        server = Arachni::RPC::Server::Base.new( opts )

        server.start

        raised = false
        begin
            Timeout::timeout( 20 ){
                sleep 0.1 while !server.ready?
            }
        rescue Exception => e
            raised = true
        end

        expect(server.ready?).to be_truthy
        expect(raised).to be_falsey
    end

    describe '#ready?' do
        context 'when the server is not ready' do
            it 'returns false' do
                expect(@server.ready?).to be_falsey
            end
        end

        context 'when the server is ready' do
            it 'returns true' do
                @server.start

                raised = false
                begin
                    Timeout::timeout( 20 ){
                        sleep 0.1 while !@server.ready?
                    }
                rescue Exception => e
                    raised = true
                end

                expect(@server.ready?).to be_truthy
                expect(raised).to be_falsey
            end
        end
    end

end
