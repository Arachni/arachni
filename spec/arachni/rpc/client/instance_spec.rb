require 'spec_helper'

describe Arachni::RPC::Client::Instance do
    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.rpc_port = available_port

        @instance = instance_spawn
    end

    context 'when connecting to an instance' do
        context 'which requires a token' do
            context 'with a valid token' do
                it 'connects successfully' do
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
    end

    describe '#opts' do
        before {
            @rpc_opts = @instance.opts
            @foo_url = Arachni::Module::Utilities.normalize_url( "http://test.com" )
        }
        context 'when assigning values' do
            it 'uses setters' do
                val = @foo_url + '1'
                (@rpc_opts.url = val).should == val
            end
            it 'passes the value as a method parameter' do
                val = @foo_url + '2'
                @rpc_opts.url( val ).should == val
            end

            describe '#set' do
                it 'allows batch assigning using a hash' do
                    val = @foo_url + '3'
                    @rpc_opts.set( url: val ).should be_true
                    @rpc_opts.url.to_s.should == val
                end
            end
        end

        it 'retrieves values' do
            val = Arachni::Module::Utilities.normalize_url( "http://test.com4" )
            @rpc_opts.url = val
            @rpc_opts.url.to_s.should == val
        end
    end

    describe '#framework' do
        before { @framework = @instance.framework }
        it 'provides access to framework methods' do
            @framework.status.should be_true
        end
    end

    describe '#modules' do
        before { @modules = @instance.modules }
        it 'provides access to module manager methods' do
            @modules.available.should be_true
        end
    end

    describe '#plugins' do
        before { @plugins = @instance.plugins }
        it 'provides access to plugin manager methods' do
            @plugins.available.should be_true
        end
    end

end
