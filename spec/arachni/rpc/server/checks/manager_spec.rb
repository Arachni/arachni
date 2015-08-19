require 'spec_helper'
require Arachni::Options.paths.lib + 'rpc/server/framework'

describe Arachni::RPC::Server::Check::Manager do
    describe '#available' do
        it 'returns an array of available checks' do
            expect(instance_spawn.checks.available).to be_any
        end
    end

    describe '#loaded' do
        context 'when there are loaded checks' do
            it 'returns an empty array' do
                expect(instance_spawn.checks.loaded).to be_empty
            end
        end
        context 'when there are loaded checks' do
            it 'returns an array of loaded checks' do
                checks = instance_spawn.checks

                expect(checks.loaded).to be_empty
                checks.load '*'
                expect(checks.loaded).to be_any
            end
        end
    end

    describe '#load' do
        it 'loads checks by name' do
            checks = instance_spawn.checks

            expect(checks.loaded).to be_empty
            checks.load 'test'
            expect(checks.loaded).to eq(['test'])
        end
    end

    describe '#load_all' do
        it 'loads all checks' do
            checks = instance_spawn.checks

            expect(checks.loaded).to be_empty
            checks.load_all
            expect(checks.loaded).to eq(checks.available)
        end
    end

end
