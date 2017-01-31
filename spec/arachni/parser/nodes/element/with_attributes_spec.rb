require 'spec_helper'

class WithAttributes
    include Arachni::Parser::Nodes::Element::WithAttributes
end

describe Arachni::Parser::Nodes::Element::WithAttributes do
    subject { WithAttributes.new }

    describe '#attributes' do
        it "returns #{described_class::Attributes}" do
            expect(subject.attributes).to be_kind_of described_class::Attributes
        end
    end

    describe '#[]' do
        it 'converts the key to string' do
            subject[:key] = 'val'

            expect(subject.attributes).to eq( 'key' => 'val' )
        end

        it 'is case insensitive' do
            subject[:kEy] = 'val'

            expect(subject.attributes).to eq( 'key' => 'val' )
        end
    end

    describe '#[]=' do
        it 'converts the key to string' do
            subject['key'] = 'val'

            expect(subject.attributes).to eq( 'key' => 'val' )
        end

        it 'is case insensitive' do
            subject[:kEy]  = 'val'
            subject['key'] = 'val2'

            expect(subject.attributes).to eq( 'key' => 'val2' )
        end

        it 'freezes the value' do
            subject['key'] = 'val'

            expect(subject['key']).to be_frozen
        end
    end
end
