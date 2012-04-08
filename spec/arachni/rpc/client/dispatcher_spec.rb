require_relative '../../../spec_helper'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/dispatcher'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/dispatcher'

describe Arachni::RPC::Client::Dispatcher do
    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.rpc_port = random_port
        @opts.pool_size = 0

        fork_em { Arachni::RPC::Server::Dispatcher.new( @opts ) }
        sleep 1

        @dispatcher = Arachni::RPC::Client::Dispatcher.new( @opts, "#{@opts.rpc_address}:#{@opts.rpc_port}" )
    end

    it 'should be able to connect to a dispatcher' do
        @dispatcher.alive?.should be_true
    end

    describe :node do
        it 'should provide access to the node data' do
            @dispatcher.node.info.is_a?( Hash ).should be_true
        end
    end

end
