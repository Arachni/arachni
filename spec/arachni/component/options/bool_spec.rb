require 'spec_helper'

describe Arachni::Component::Options::Bool do
    include_examples 'component_option'

    let(:trues) { [ true, 'y', 'yes', '1', 1, 't', 'true', 'on' ] }
    let(:falses) { [ false, 'n', 'no', '0', 0, 'f', 'false', 'off', '' ] }

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                trues.each do |v|
                    expect(described_class.new( '', value: v ).valid?).to be_truthy
                end
            end
        end

        context 'when the value is not valid' do
            it 'returns false' do
                expect(described_class.new( '', value: 'dds' ).valid?).to be_falsey
            end
        end
    end

    describe '#normalize' do
        it 'converts the string input into a boolean value' do
            trues.each { |v| expect(described_class.new( '', value: v  ).normalize).to be_truthy }
            falses.each { |v| expect(described_class.new( '', value: v  ).normalize).to be_falsey }
        end
    end

    describe '#true?' do
        context 'when the value option represents true' do
            it 'returns true' do
                trues.each { |v| expect(described_class.new( '', value: v  ).true?).to be_truthy }
            end
        end
        context 'when the value option represents false' do
            it 'returns false' do
                falses.each { |v| expect(described_class.new( '', value: v  ).true?).to be_falsey }
            end
        end
    end

    describe '#false?' do
        context 'when the value option represents false' do
            it 'returns true' do
                falses.each { |v| expect(described_class.new( '', value: v  ).false?).to be_truthy }
            end
        end
        context 'when the value option represents true' do
            it 'returns false' do
                trues.each { |v| expect(described_class.new( '', value: v  ).false?).to be_falsey }
            end
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            expect(described_class.new( '' ).type).to eq(:bool)
        end
    end

end
