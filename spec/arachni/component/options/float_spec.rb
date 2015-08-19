require 'spec_helper'

describe Arachni::Component::Options::Float do
    include_examples 'component_option'
    subject { described_class.new( '' ) }

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                ['1', 1, '1.2'].each do |value|
                    subject.value = value
                    expect(subject.valid?).to be_truthy
                end
            end
        end
        context 'when the value is not valid' do
            it 'returns false' do
                subject.value = '4d'
                expect(subject.valid?).to be_falsey
            end
        end
    end

    describe '#normalize' do
        it 'converts the string input into a boolean value' do
            subject.value = '5'
            expect(subject.normalize).to eq(5.0)

            subject.value = '5.3'
            expect(subject.normalize).to eq(5.3)

            subject.value = 3
            expect(subject.normalize).to eq(3.0)
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            expect(subject.type).to eq(:float)
        end
    end

end
