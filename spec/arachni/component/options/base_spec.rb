require 'spec_helper'

describe Arachni::Component::Options::Base do
    include_examples 'component_option'

    describe '#normalize' do
        it 'returns the value as is' do
            expect(described_class.new( '', value: 'blah' ).normalize).to eq('blah')
        end

        context 'when no #value is set' do
            it 'returns #default' do
                expect(described_class.new( '', default: 'test' ).normalize).to eq('test')
            end
        end
    end

    describe '#valid?' do
        context 'when the option is required' do
            context 'and the value is not empty' do
                it 'returns true' do
                    expect(described_class.new( '', required: true, value: 'stuff' ).valid?).to be_truthy
                end
            end

            context 'and the value is nil' do
                it 'returns false' do
                    expect(described_class.new( '', required: true ).valid?).to be_falsey
                end
            end
        end

        context 'when the option is not required' do
            context 'and the value is not empty' do
                it 'returns true' do
                    expect(described_class.new( '', value: 'true' ).valid?).to be_truthy
                end
            end

            context 'and the value is empty' do
                it 'returns true' do
                    expect(described_class.new( '' ).valid?).to be_truthy
                end
            end
        end
    end

    describe '#type' do
        it 'returns the option type' do
            expect(described_class.new( '' ).type).to eq(:abstract)
        end
    end
end
