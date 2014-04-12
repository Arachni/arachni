require 'spec_helper'

describe Arachni::Component::Options::Bool do
    let(:trues) { [ true, 'y', 'yes', '1', 1, 't', 'true', 'on' ] }
    let(:falses) { [ false, 'n', 'no', '0', 0, 'f', 'false', 'off', '' ] }

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                trues.each do |v|
                    described_class.new( '', value: v ).valid?.should be_true
                end
            end
        end

        context 'when the value is not valid' do
            it 'returns false' do
                described_class.new( '', value: 'dds' ).valid?.should be_false
            end
        end
    end

    describe '#normalize' do
        it 'converts the string input into a boolean value' do
            trues.each { |v| described_class.new( '', value: v  ).normalize.should be_true }
            falses.each { |v| described_class.new( '', value: v  ).normalize.should be_false }
        end
    end

    describe '#true?' do
        context 'when the value option represents true' do
            it 'returns true' do
                trues.each { |v| described_class.new( '', value: v  ).true?.should be_true }
            end
        end
        context 'when the value option represents false' do
            it 'returns false' do
                falses.each { |v| described_class.new( '', value: v  ).true?.should be_false }
            end
        end
    end

    describe '#false?' do
        context 'when the value option represents false' do
            it 'returns true' do
                falses.each { |v| described_class.new( '', value: v  ).false?.should be_true }
            end
        end
        context 'when the value option represents true' do
            it 'returns false' do
                trues.each { |v| described_class.new( '', value: v  ).false?.should be_false }
            end
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            described_class.new( '' ).type.should == 'bool'
        end
    end

end
