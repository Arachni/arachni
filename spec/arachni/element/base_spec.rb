require 'spec_helper'

describe Arachni::Element::Base do
    before( :all ) do
        @utils =  Arachni::Utilities
    end

    let( :url ) do
        'http://test.com'
    end

    let( :normalized_url ) do
        Arachni::Utilities.normalize_url( 'http://test.com' )
    end

    let( :options ) do
        {
            url:    url,
            inputs: { hash: 'stuff' }
        }
    end

    subject do
        described_class.new options
    end

    describe '#url' do
        it 'returns the assigned URL' do
            subject.url.should == normalized_url
        end
    end

    describe '#url=' do
        it 'normalizes the passed URL' do
            url = 'http://test.com/some stuff#frag!'
            subject.url = url
            subject.url.should == @utils.normalize_url( url )
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

        it 'removed the associated #page' do
            subject.page = Factory[:page]
            subject.dup.page.should be_nil
        end
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            subject.to_h.should == {
                type: :base,
                url:  subject.url
            }
        end
    end
end
