require 'spec_helper'

describe Arachni::RPC::Server::Module::Manager do
    describe '#available' do
        it 'returns an array of available modules' do
            instance_spawn.modules.available.should be_any
        end
    end

    describe '#loaded' do
        context 'when there are loaded modules' do
            it 'returns an empty array' do
                instance_spawn.modules.loaded.should be_empty
            end
        end
        context 'when there are loaded modules' do
            it 'returns an array of loaded modules' do
                modules = instance_spawn.modules

                modules.loaded.should be_empty
                modules.load '*'
                modules.loaded.should be_any
            end
        end
    end

    describe '#load' do
        it 'loads modules by name' do
            modules = instance_spawn.modules

            modules.loaded.should be_empty
            modules.load 'test'
            modules.loaded.should == ['test']
        end
    end

    describe '#load_all' do
        it 'loads all modules' do
            modules = instance_spawn.modules

            modules.loaded.should be_empty
            modules.load_all
            modules.loaded.should == modules.available
        end
    end

end
