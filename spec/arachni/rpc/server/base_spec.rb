require 'spec_helper'

describe Arachni::RPC::Server::Base do
    before( :all ) do
        opts = Arachni::Options.instance
        opts.rpc_port = available_port
        @server = Arachni::RPC::Server::Base.new( opts )
    end

    it 'supports UNIX sockets' do
        opts = Arachni::Options.instance
        opts.rpc_address = nil
        opts.rpc_port    = nil
        opts.rpc_socket  = '/tmp/arachni-base-server'
        server = Arachni::RPC::Server::Base.new( opts )

        Thread.new{ server.run }
        raised = false
        begin
            Timeout::timeout( 20 ){
                sleep 0.1 while !server.ready?
            }
        rescue Exception => e
            raised = true
        end

        server.ready?.should be_true
        raised.should be_false
    end

    describe '#ready?' do
        context 'when the server is not ready' do
            it 'returns false' do
                @server.ready?.should be_false
            end
        end

        context 'when the server is ready' do
            it 'returns true' do
                Thread.new{ @server.run }
                raised = false
                begin
                    Timeout::timeout( 20 ){
                        sleep 0.1 while !@server.ready?
                    }
                rescue Exception => e
                    raised = true
                end

                @server.ready?.should be_true
                raised.should be_false
            end
        end
    end

end
