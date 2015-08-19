require 'spec_helper'

describe Arachni::Component::Options::Int do
    include_examples 'component_option'
    subject { described_class.new( '' ) }

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                ['1', 1, 0, '0'].each do |value|
                    subject.value = value
                    expect(subject.valid?).to be_truthy
                end
            end
        end

        context 'when the value is not valid' do
            it 'returns false' do
                %w(sd 4d).each do |value|
                    subject.value = value
                    expect(subject.valid?).to be_falsey
                end
            end
        end
    end

    describe '#normalize' do
        it 'converts the string input into a boolean value' do
            subject.value = '5'
            expect(subject.normalize).to eq(5)

            subject.value = 3
            expect(subject.normalize).to eq(3)
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            expect(subject.type).to eq(:integer)
        end
    end

end
