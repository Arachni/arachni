require 'spec_helper'

describe Arachni::Component::Options::Address do
    include_examples 'component_option'

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                expect(described_class.new( '', value: 'localhost' )).to be_truthy
            end
        end

        context 'when the value is not valid' do
            it 'returns false' do
                expect(described_class.new( '', value: 'stuff' ).valid?).to be_falsey
            end
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            expect(described_class.new( '' ).type).to eq(:address)
        end
    end

end
