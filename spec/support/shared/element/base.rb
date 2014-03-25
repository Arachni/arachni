require 'spec_helper'

shared_examples_for 'element' do
    let( :normalized_url ) do
        Arachni::Utilities.normalize_url( 'http://test.com' )
    end

    describe '#marshal_dump' do
        it 'excludes #page' do
            subject.page = Factory[:page]
            subject.marshal_dump.should_not include :page
        end
    end

    describe '#url=' do
        it 'normalizes the passed URL' do
            url = 'http://test.com/some stuff#frag!'
            subject.url = url
            subject.url.should == Arachni::Utilities.normalize_url( url )
        end
    end

    describe '#page=' do
        it 'sets the associated page' do
            subject.page = Factory[:page]
            subject.page.should == Factory[:page]
        end
    end

    describe '#dup' do
        it 'returns a copy of self' do
            subject.dup.to_h.should == subject.to_h
        end
    end

    describe '#to_h' do
        let(:hash) { subject.to_h }

        it 'includes the #type' do
            hash[:type].should == subject.type
        end

        it 'includes the #url' do
            hash[:url].should == subject.url
        end

        it 'includes the element class' do
            hash[:class].should == described_class
        end
    end
end
