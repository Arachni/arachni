require 'spec_helper'

describe Arachni::Parser::Nodes::Element do
    subject { described_class.new( name ) }
    let(:name) { 'dIv' }

    describe '#name' do
        it 'returns the given value' do
            expect(subject.name).to eq :div
        end
    end

    describe '#to_html' do
        it 'returns the given value' do
            expect(subject.to_html).to eq "<div>\n</div>\n"
        end
    end
end
