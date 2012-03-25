require_relative '../../../spec_helper'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/dispatcher'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/dispatcher'

describe Arachni::RPC::Client::Dispatcher do
    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.rpc_address = 'localhost'
        @opts.rpc_port = 9999
        @opts.pool_size = 0

        @pid = fork { Arachni::RPC::Server::Dispatcher.new( @opts ) }
        sleep 1

        @dispatcher = Arachni::RPC::Client::Dispatcher.new( @opts, "#{@opts.rpc_address}:#{@opts.rpc_port}" )
    end

    after( :all ){
        Process.kill( 'KILL', @pid )
        @opts.reset!
    }

    it 'should be able to connect to a dispatcher' do
        @dispatcher.alive?.should be_true
    end

    describe :node do
        it 'should provide access to the node data' do
            @dispatcher.node.info.is_a?( Hash ).should be_true
        end
    end

end
