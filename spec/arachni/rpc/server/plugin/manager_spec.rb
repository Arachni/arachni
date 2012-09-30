require_relative '../../../../spec_helper'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/instance'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/instance'

describe Arachni::RPC::Server::Plugin::Manager do
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

        @plugins = Arachni::RPC::Client::Instance.new( @opts,
            "#{@opts.rpc_address}:#{port1}", @token
        ).plugins

        @plugins_clean = Arachni::RPC::Client::Instance.new( @opts,
            "#{@opts.rpc_address}:#{port2}", @token
        ).plugins
    end

    describe '#available' do
        it 'should return an array of available plugins' do
            @plugins.available.should be_any
        end
    end

    describe '#loaded' do
        context 'when there are loaded plugins' do
            it 'should return an empty array' do
                @plugins.loaded.should be_empty
            end
        end
        context 'when there are loaded plugins' do
            it 'should return an array of loaded plugins' do
                @plugins.load( { 'default' => {}} )
                @plugins.loaded.should be_any
            end
        end
    end

    describe '#load' do
        it 'should load plugins by name' do
            @plugins_clean.load( { 'default' => {}} )
            @plugins_clean.loaded.should == ['default']
        end

        context 'with invalid options' do
            it 'should throw an exception' do
                raised = false
                begin
                    @plugins_clean.load( { 'with_options' => {}} )
                rescue Exception
                    raised = true
                end
                raised.should be_true
            end
        end
    end

    describe '#merge_results' do
        it 'should merge the results of the distributable plugins' do
            framework = Arachni::RPC::Server::Framework.new( Arachni::Options.instance )
            plugins = framework.plugins
            plugins.load( { 'distributable' => {}} )
            plugins.loaded.should == ['distributable']

            results = [ 'distributable' => { results: { stuff: 2 } } ]
            plugins.register_results( Arachni::Plugins::Distributable.new( framework, {} ), stuff: 1 )
            plugins.merge_results( results )['distributable'][:results][:stuff].should == 3
            plugins.clear
        end
    end

end
