require 'spec_helper'

describe Arachni::Component::Options::String do
    include_examples 'component_option'
    subject { described_class.new( '' ) }

    describe '#valid?' do
        it 'returns true' do
            ['test', 999, true].each do |value|
                subject.value = value
                expect(subject.valid?).to be_truthy
            end
        end
    end

    describe '#normalize' do
        it 'returns a string representation of the value' do
            subject.value = 'test'
            expect(subject.normalize).to eq('test')
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            expect(subject.type).to eq(:string)
        end
    end

end
