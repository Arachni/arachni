require 'spec_helper'

describe Arachni::RPC::Client::Instance do
    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.rpc.server_port = available_port

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
                    expect do
                        described_class.new( @opts, @instance.url, 'blah' ).service.alive?
                    end.to raise_error Arachni::RPC::Exceptions::InvalidToken
                end
            end
        end
    end

    describe '#opts' do
        before do
            @rpc_opts = @instance.opts
            @foo_url  = Arachni::Utilities.normalize_url( 'http://test.com' )
        end

        describe '#set' do
            it 'allows batch assigning using a hash' do
                val = @foo_url + '3'
                @rpc_opts.set( url: val ).should be_true
                @rpc_opts.url.to_s.should == val
            end
        end
    end

    describe '#framework' do
        before { @framework = @instance.framework }
        it 'provides access to framework methods' do
            @framework.status.should be_true
        end
    end

    describe '#checks' do
        before { @checks = @instance.checks }
        it 'provides access to checks manager methods' do
            @checks.available.should be_true
        end
    end

    describe '#plugins' do
        before { @plugins = @instance.plugins }
        it 'provides access to plugin manager methods' do
            @plugins.available.should be_true
        end
    end

end
