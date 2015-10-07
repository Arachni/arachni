require 'spec_helper'
require "#{Arachni::Options.paths.lib}/rpc/server/framework"

describe 'Arachni::RPC::Server::Plugin::Manager' do

    describe '#available' do
        it 'returns an array of available plugins' do
            expect(instance_spawn.plugins.available).to be_any
        end
    end

    describe '#loaded' do
        context 'when there are loaded plugins' do
            it 'returns an empty array' do
                expect(instance_spawn.plugins.loaded).to be_empty
            end
        end
        context 'when there are loaded plugins' do
            it 'returns an array of loaded plugins' do
                plugins = instance_spawn.plugins

                plugins.load( { 'default' => {}} )
                expect(plugins.loaded).to be_any
            end
        end
    end

    describe '#load' do
        it 'loads plugins by name' do
            plugins = instance_spawn.plugins

            plugins.load( { 'default' => {}} )
            expect(plugins.loaded).to eq(['default'])
        end

        context 'with invalid options' do
            it 'throws an exception' do
                raised = false
                begin
                    instance_spawn.plugins.load( { 'with_options' => {}} )
                rescue Exception
                    raised = true
                end
                expect(raised).to be_truthy
            end
        end
    end

    describe '#merge_results' do
        it "delegates to ##{Arachni::Data::Plugins}#merge_results" do
            plugins = Arachni::RPC::Server::Framework.new.plugins
            expect(Arachni::Data.plugins).to receive(:merge_results)
            plugins.merge_results( [ distributable: { results: { stuff: 2 } } ] )
        end
    end

end
