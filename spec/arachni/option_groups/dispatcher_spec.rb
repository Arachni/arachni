require 'spec_helper'

describe Arachni::OptionGroups::Dispatcher do
    include_examples 'option_group'
    subject { described_class.new }

    %w(url external_address pool_size instance_port_range neighbour
        node_ping_interval node_cost node_pipe_id node_weight node_nickname
    ).each do |method|
        it { should respond_to method }
        it { should respond_to "#{method}=" }
    end

    describe '#grid?' do
        it 'defaults to false' do
            subject.grid?.should be_false
        end

        describe 'when the option has been enabled' do
            context 'via #grid=' do
                it 'returns true' do
                    subject.grid = true
                    subject.grid?.should be_true
                end
            end

            context 'via #grid_mode=' do
                it 'returns true' do
                    subject.grid_mode = :balance
                    subject.grid?.should be_true
                end
            end
        end
        describe 'when the option has been disabled' do
            context 'via #grid=' do
                it 'returns false' do
                    subject.grid = false
                    subject.grid?.should be_false
                end
            end

            context 'via #grid_mode=' do
                it 'returns false' do
                    subject.grid_mode = false
                    subject.grid?.should be_false
                end
            end
        end
        describe 'by default' do
            it 'returns false' do
                subject.grid?.should be_false
            end
        end
    end

    describe '#grid=' do
        context true do
            it 'is a shorthand for #grid_mode = :balance' do
                subject.grid = true
                subject.grid_mode.should == :balance
            end
        end
    end

    describe '#grid_mode=' do
        context 'when given' do
            context String do
                it 'converts it to Symbol and sets the option' do
                    subject.grid_mode = 'balance'
                    subject.grid_mode.should == :balance
                end
            end

            context Symbol do
                it 'sets the option' do
                    subject.grid_mode = :aggregate
                    subject.grid_mode.should == :aggregate
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
                subject.grid_aggregate?.should be_false
                subject.grid_mode = :aggregate
                subject.grid_aggregate?.should be_true
            end
        end
        context 'when in :balance mode' do
            it 'returns false' do
                subject.grid_aggregate?.should be_false
                subject.grid_mode = :balance
                subject.grid_aggregate?.should be_false
            end
        end
    end

    describe '#grid_balance?' do
        context 'when in :balance mode' do
            it 'returns true' do
                subject.grid_balance?.should be_false
                subject.grid_mode = :balance
                subject.grid_balance?.should be_true
            end
        end
        context 'when in :balance mode' do
            it 'returns false' do
                subject.grid_balance?.should be_false
                subject.grid_mode = :aggregate
                subject.grid_balance?.should be_false
            end
        end
    end

end
