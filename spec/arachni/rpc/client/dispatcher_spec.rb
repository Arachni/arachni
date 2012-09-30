require_relative '../../../spec_helper'
require 'fileutils'
require Arachni::Options.instance.dir['lib'] + 'rpc/client/dispatcher'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/dispatcher'

describe Arachni::RPC::Client::Dispatcher do
    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.rpc_port = random_port
        @opts.pool_size = 0

        @handler_lib = Arachni::Options.dir['rpcd_handlers']
        FileUtils.cp( "#{fixtures_path}rpcd_handlers/echo.rb", @handler_lib )

        fork_em { Arachni::RPC::Server::Dispatcher.new( @opts ) }
        sleep 1

        @dispatcher = Arachni::RPC::Client::Dispatcher.new( @opts, "#{@opts.rpc_address}:#{@opts.rpc_port}" )
    end

    after( :all ) do
        FileUtils.rm( "#{@handler_lib}echo.rb" )
    end

    it 'should be able to connect to a dispatcher' do
        @dispatcher.alive?.should be_true
    end

    it 'should map the remote handlers to local objects' do
        args = [ 'stuff', 'here', { blah: true } ]
        @dispatcher.echo.echo( *args ).should == args
    end

    describe '#node' do
        it 'should provide access to the node data' do
            @dispatcher.node.info.is_a?( Hash ).should be_true
        end
    end

end
