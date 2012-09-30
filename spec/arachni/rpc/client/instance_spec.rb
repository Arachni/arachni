require_relative '../../../spec_helper'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/instance'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/instance'

describe Arachni::RPC::Client::Instance do
    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.rpc_port = random_port

        @token = 'secret!'

        fork_em { Arachni::RPC::Server::Instance.new( @opts, @token ) }
        sleep 1

        @instance = Arachni::RPC::Client::Instance.new( @opts, "#{@opts.rpc_address}:#{@opts.rpc_port}", @token )
    end

    context 'when connecting to an instance which requires a token' do
        context 'with a valid token' do
            it 'should be able to connect successfully' do
                @instance.service.alive?.should be_true
            end
        end
        context 'with an invalid token' do
            it 'should fail to connect' do
                inst = Arachni::RPC::Client::Instance.new( @opts, "#{@opts.rpc_address}:#{@opts.rpc_port}", 'blah' )

                raised = false
                begin
                    inst.service.alive?.should be_true
                rescue Arachni::RPC::Exceptions::InvalidToken
                    raised = true
                end
                raised.should be_true
            end
        end
    end

    describe '#opts' do
        before {
            @rpc_opts = @instance.opts
            @foo_url = Arachni::Module::Utilities.normalize_url( "http://test.com" )
        }
        context 'when assigning values' do
            it 'should be able to use setters' do
                val = @foo_url + '1'
                (@rpc_opts.url = val).should == val
            end
            it 'should be able to pass the value as a method param' do
                val = @foo_url + '2'
                @rpc_opts.url( val ).should == val
            end

            describe '#set' do
                it 'should allow batch assigning using a hash' do
                    val = @foo_url + '3'
                    @rpc_opts.set( url: val ).should be_true
                    @rpc_opts.url.to_s.should == val
                end
            end
        end

        it 'should be able to retrieve values' do
            val = Arachni::Module::Utilities.normalize_url( "http://test.com4" )
            @rpc_opts.url = val
            @rpc_opts.url.to_s.should == val
        end
    end

    describe '#framework' do
        before { @framework = @instance.framework }
        it 'should provide access to framework methods' do
            @framework.status.should be_true
        end
    end

    describe '#modules' do
        before { @modules = @instance.modules }
        it 'should provide access to module manager methods' do
            @modules.available.should be_true
        end
    end

    describe '#plugins' do
        before { @plugins = @instance.plugins }
        it 'should provide  access to plugin manager methods' do
            @plugins.available.should be_true
        end
    end

end
