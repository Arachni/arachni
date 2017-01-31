require 'spec_helper'

describe Arachni::Parser::Nodes::Text do
    subject { described_class.new( value ) }
    let(:value) { 'my text' }

    describe '#value' do
        it 'returns the given value' do
            expect(subject.value).to eq value
        end
    end

    describe '#text' do
        it 'returns the given value' do
            expect(subject.text).to eq value
        end
    end

    describe '#to_html' do
        it 'returns the given value' do
            expect(subject.to_html).to eq "my text\n"
        end
    end
end
