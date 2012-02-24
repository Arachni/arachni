require_relative '../../../spec_helper'

describe Arachni::Parser::Element::Base do
    before( :all ) do
        @url = 'http://test.com'
        @raw = { raw: { hash: 'stuff' } }
        @e = Arachni::Parser::Element::Base.new( @url, @raw )
    end

    it 'should have the assigned URL' do
        @e.url.should == @url
    end

    it 'should have the assigned raw data' do
        @e.raw.should == @raw
    end

end
