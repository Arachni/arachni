require 'spec_helper'

describe Arachni::Parser::Nodes::Element::WithAttributes::Attributes do
    subject { described_class.new }

    describe '#[]' do
        it 'converts the key to string' do
            subject[:key] = 'val'

            expect(subject).to eq( 'key' => 'val' )
        end

        it 'is case insensitive' do
            subject[:kEy] = 'val'

            expect(subject).to eq( 'key' => 'val' )
        end
    end

    describe '#[]=' do
        it 'converts the key to string' do
            subject['key'] = 'val'

            expect(subject).to eq( 'key' => 'val' )
        end

        it 'is case insensitive' do
            subject[:kEy]  = 'val'
            subject['key'] = 'val2'

            expect(subject).to eq( 'key' => 'val2' )
        end

        it 'freezes the value' do
            subject['key'] = 'val'

            expect(subject['key']).to be_frozen
        end
    end
end
