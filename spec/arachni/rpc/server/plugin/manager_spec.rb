require 'spec_helper'

describe Arachni::RPC::Server::Plugin::Manager do

    describe '#available' do
        it 'returns an array of available plugins' do
            instance_spawn.plugins.available.should be_any
        end
    end

    describe '#loaded' do
        context 'when there are loaded plugins' do
            it 'returns an empty array' do
                instance_spawn.plugins.loaded.should be_empty
            end
        end
        context 'when there are loaded plugins' do
            it 'returns an array of loaded plugins' do
                plugins = instance_spawn.plugins

                plugins.load( { 'default' => {}} )
                plugins.loaded.should be_any
            end
        end
    end

    describe '#load' do
        it 'loads plugins by name' do
            plugins = instance_spawn.plugins

            plugins.load( { 'default' => {}} )
            plugins.loaded.should == ['default']
        end

        context 'with invalid options' do
            it 'throws an exception' do
                raised = false
                begin
                    instance_spawn.plugins.load( { 'with_options' => {}} )
                rescue Exception
                    raised = true
                end
                raised.should be_true
            end
        end
    end

    describe '#merge_results' do
        it 'merges the results of the distributable plugins' do
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
