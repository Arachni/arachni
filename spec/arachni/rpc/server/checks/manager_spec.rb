require 'spec_helper'
require Arachni::Options.dir['lib'] + 'rpc/server/framework'

describe Arachni::RPC::Server::Check::Manager do
    describe '#available' do
        it 'returns an array of available checks' do
            instance_spawn.checks.available.should be_any
        end
    end

    describe '#loaded' do
        context 'when there are loaded checks' do
            it 'returns an empty array' do
                instance_spawn.checks.loaded.should be_empty
            end
        end
        context 'when there are loaded checks' do
            it 'returns an array of loaded checks' do
                checks = instance_spawn.checks

                checks.loaded.should be_empty
                checks.load '*'
                checks.loaded.should be_any
            end
        end
    end

    describe '#load' do
        it 'loads checks by name' do
            checks = instance_spawn.checks

            checks.loaded.should be_empty
            checks.load 'test'
            checks.loaded.should == ['test']
        end
    end

    describe '#load_all' do
        it 'loads all checks' do
            checks = instance_spawn.checks

            checks.loaded.should be_empty
            checks.load_all
            checks.loaded.should == checks.available
        end
    end

end
