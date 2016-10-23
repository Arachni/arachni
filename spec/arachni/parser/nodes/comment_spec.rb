require 'spec_helper'

describe Arachni::Parser::Nodes::Comment do
    subject { described_class.new( value ) }
    let(:value) { 'my comment' }

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
            expect(subject.to_html).to eq "<!-- my comment -->\n"
        end
    end
end
