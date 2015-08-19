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
                    expect(@instance.service.alive?).to be_truthy
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

    describe '#options' do
        before do
            @rpc_opts = @instance.options
            @foo_url  = Arachni::Utilities.normalize_url( 'http://test.com' )
        end

        describe '#set' do
            it 'allows batch assigning using a hash' do
                val = @foo_url + '3'
                expect(@rpc_opts.set( url: val )).to be_truthy
                expect(@rpc_opts.url.to_s).to eq(val)
            end
        end
    end

    describe '#framework' do
        before { @framework = @instance.framework }
        it 'provides access to framework methods' do
            expect(@framework.status).to be_truthy
        end
    end

    describe '#checks' do
        before { @checks = @instance.checks }
        it 'provides access to checks manager methods' do
            expect(@checks.available).to be_truthy
        end
    end

    describe '#plugins' do
        before { @plugins = @instance.plugins }
        it 'provides access to plugin manager methods' do
            expect(@plugins.available).to be_truthy
        end
    end

end
