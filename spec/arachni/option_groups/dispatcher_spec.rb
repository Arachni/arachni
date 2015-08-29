require 'spec_helper'

describe Arachni::OptionGroups::Dispatcher do
    include_examples 'option_group'
    subject { described_class.new }

    %w(url external_address pool_size instance_port_range neighbour
        node_ping_interval node_cost node_pipe_id node_weight node_nickname
    ).each do |method|
        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end

    describe '#grid?' do
        it 'defaults to false' do
            expect(subject.grid?).to be_falsey
        end

        describe 'when the option has been enabled' do
            context 'via #grid=' do
                it 'returns true' do
                    subject.grid = true
                    expect(subject.grid?).to be_truthy
                end
            end

            context 'via #grid_mode=' do
                it 'returns true' do
                    subject.grid_mode = :balance
                    expect(subject.grid?).to be_truthy
                end
            end
        end
        describe 'when the option has been disabled' do
            context 'via #grid=' do
                it 'returns false' do
                    subject.grid = false
                    expect(subject.grid?).to be_falsey
                end
            end

            context 'via #grid_mode=' do
                it 'returns false' do
                    subject.grid_mode = false
                    expect(subject.grid?).to be_falsey
                end
            end
        end
        describe 'by default' do
            it 'returns false' do
                expect(subject.grid?).to be_falsey
            end
        end
    end

    describe '#grid=' do
        context 'true' do
            it 'is a shorthand for #grid_mode = :balance' do
                subject.grid = true
                expect(subject.grid_mode).to eq(:balance)
            end
        end
    end

    describe '#grid_mode=' do
        context 'when given' do
            context 'String' do
                it 'converts it to Symbol and sets the option' do
                    subject.grid_mode = 'balance'
                    expect(subject.grid_mode).to eq(:balance)
                end
            end

            context 'Symbol' do
                it 'sets the option' do
                    subject.grid_mode = :aggregate
                    expect(subject.grid_mode).to eq(:aggregate)
                end
            end

            context 'an invalid option' do
                it 'raises ArgumentError' do
                    expect { subject.grid_mode = :stuff }.to raise_error ArgumentError
                end
            end
        end
    end

    describe '#grid_aggregate?' do
        context 'when in :aggregate mode' do
            it 'returns true' do
                expect(subject.grid_aggregate?).to be_falsey
                subject.grid_mode = :aggregate
                expect(subject.grid_aggregate?).to be_truthy
            end
        end
        context 'when in :balance mode' do
            it 'returns false' do
                expect(subject.grid_aggregate?).to be_falsey
                subject.grid_mode = :balance
                expect(subject.grid_aggregate?).to be_falsey
            end
        end
    end

    describe '#grid_balance?' do
        context 'when in :balance mode' do
            it 'returns true' do
                expect(subject.grid_balance?).to be_falsey
                subject.grid_mode = :balance
                expect(subject.grid_balance?).to be_truthy
            end
        end
        context 'when in :balance mode' do
            it 'returns false' do
                expect(subject.grid_balance?).to be_falsey
                subject.grid_mode = :aggregate
                expect(subject.grid_balance?).to be_falsey
            end
        end
    end

end
