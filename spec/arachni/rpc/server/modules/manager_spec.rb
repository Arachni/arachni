require_relative '../../../../spec_helper'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/instance'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/instance'

describe Arachni::RPC::Server::Module::Manager do
    before( :all ) do
        @opts = Arachni::Options.instance
        port1 = random_port
        port2 = random_port

        @token = 'secret!'

        fork_em {
            @opts.rpc_port = port1
            Arachni::RPC::Server::Instance.new( @opts, @token )
        }
        fork_em {
            @opts.rpc_port = port2
            Arachni::RPC::Server::Instance.new( @opts, @token )
        }
        sleep 1

        @modules = Arachni::RPC::Client::Instance.new( @opts,
            "#{@opts.rpc_address}:#{port1}", @token
        ).modules

        @modules_clean = Arachni::RPC::Client::Instance.new( @opts,
            "#{@opts.rpc_address}:#{port2}", @token
        ).modules
    end

    describe :available do
        it 'should return an array of available modules' do
            @modules.available.should be_any
        end
    end

    describe :loaded do
        context 'when there are loaded modules' do
            it 'should return an empty array' do
                @modules.loaded.should be_empty
            end
        end
        context 'when there are loaded modules' do
            it 'should return an array of loaded modules' do
                @modules.load( '*' )
                @modules.loaded.should be_any
            end
        end
    end

    describe :load do
        it 'should load modules by name' do
            @modules_clean.load( 'test' )
            @modules_clean.loaded.should == ['test']
        end
    end

end
