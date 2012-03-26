require_relative '../../../spec_helper'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/base'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/base'

require 'ostruct'

describe Arachni::RPC::Server::Base do
    before( :all ) do
        opts = OpenStruct.new
        opts.rpc_port = random_port
        opts.rpc_address = 'localhost'
        @server = Arachni::RPC::Server::Base.new( opts )
    end

    after( :all ) { kill_em! }

    describe :ready? do
        context 'when the server is not ready' do
            it 'should be false' do
                @server.ready?.should be_false
            end
        end

        context 'when the server is ready' do
            it 'should be true' do
                Thread.new{ @server.run }
                sleep 1
                @server.ready?.should be_true
            end
        end
    end

end
