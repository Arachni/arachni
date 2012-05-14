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

    describe '#==' do
        it 'should assert equality based on method, action and inputs' do
            e = Arachni::Parser::Element::Link.new( @url, inputs: { 'name' => 'val' } )
            c = Arachni::Parser::Element::Link.new( @url, inputs: { 'name' => 'val' } )
            c.should == e

            e = Arachni::Parser::Element::Form.new( @url, inputs: { 'name' => 'val' } )
            c = Arachni::Parser::Element::Form.new( @url, inputs: { 'name' => 'val' } )
            c.should == e

            e = Arachni::Parser::Element::Form.new( @url, method: 'post', inputs: { 'name' => 'val' } )
            c = Arachni::Parser::Element::Form.new( @url, method: 'post', inputs: { 'name' => 'val' } )
            c.should == e

            e = Arachni::Parser::Element::Form.new( @url, inputs: { 'name' => 'val' } )
            c = Arachni::Parser::Element::Form.new( @url, method: 'get', inputs: { 'name' => 'val' } )
            c.should_not == e

            e = Arachni::Parser::Element::Form.new( @url, inputs: { 'name' => 'val' } )
            c = Arachni::Parser::Element::Form.new( @url + 's', inputs: { 'name' => 'val' } )
            c.should_not == e

            e = Arachni::Parser::Element::Form.new( @url, inputs: { 'name' => 'val' } )
            c = Arachni::Parser::Element::Form.new( @url, inputs: { 'name2' => 'val' } )
            c.should_not == e
        end
    end

    describe '#dup' do
        before do
            @elem = Arachni::Parser::Element::Link.new( @url, inputs: { 'name' => 'val' } )
        end
        it 'should duplicate the element' do
            e = @elem.dup
            e.should == @elem
            e.url = 'blah'
            e.auditable['crap'] = 'stuff'
            @elem.auditable['crap'].should be_nil
            @elem.url.should == @url
        end
        it 'should maintain the scope override' do
            e = @elem.dup
            e.override_instance_scope?.should be_false
            e.override_instance_scope?.should == @elem.override_instance_scope?

            e.override_instance_scope!
            c = e.dup
            e.override_instance_scope?.should be_true
            c.override_instance_scope?.should == e.override_instance_scope?

            a = @elem.dup
            a.override_instance_scope!
            a.override_instance_scope?.should_not == @elem.override_instance_scope?
        end
    end

end
