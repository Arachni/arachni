require 'spec_helper'

describe Arachni::Parser::WithChildren do
    subject { Arachni::Parser::Nodes::Element.new( :stuff ) }

    describe '#children' do
        context 'by default' do
            it 'is empty' do
                expect(subject.children).to be_empty
            end
        end
    end

    describe '#parent' do
        context 'by default' do
            let(:html) { '' }

            it 'is empty' do
                expect(subject.children).to be_empty
            end
        end
    end

    describe '#<<' do
        let(:other) { Arachni::Parser::Nodes::Element.new( :stuff ) }

        it 'adds a child' do
            subject << other
            expect(subject.children).to eq [other]
        end

        it 'sets the #parent on the child' do
            subject << other
            expect(other.parent).to eq subject
        end
    end
end
