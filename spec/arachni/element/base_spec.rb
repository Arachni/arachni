require 'spec_helper'

describe Arachni::Element::Base do
    before( :all ) do
        @utils=  Arachni::Utilities
        @url = @utils.normalize_url( 'http://test.com' )

        @options = {
            url:    @url,
            inputs: { hash: 'stuff' }
        }
        @e = described_class.new( @options )
    end

    describe '#url' do
        it 'returns the assigned URL' do
            @e.url.should == @url
        end
    end

    describe '#url=' do
        it 'normalizes the passed URL' do
            e = Arachni::Element::Base.new( @options )
            url = 'http://test.com/some stuff#frag!'
            e.url = url
            e.url.should == @utils.normalize_url( url )
        end
    end

    describe '#==' do
        it 'asserts equality based on method, action and inputs' do
            e = Arachni::Element::Form.new( url: @url, inputs: { 'name' => 'val' } )
            c = Arachni::Element::Form.new( url: @url, inputs: { 'name' => 'val' } )
            c.should == e

            e = Arachni::Element::Form.new( url: @url, inputs: { 'name' => 'val' } )
            c = Arachni::Element::Form.new( url: @url, inputs: { 'name' => 'val' } )
            c.should == e

            e = Arachni::Element::Form.new( url: @url, method: 'post', inputs: { 'name' => 'val' } )
            c = Arachni::Element::Form.new( url: @url, method: 'post', inputs: { 'name' => 'val' } )
            c.should == e

            e = Arachni::Element::Form.new( url: @url, inputs: { 'name' => 'val' } )
            c = Arachni::Element::Form.new( url: @url, method: 'post', inputs: { 'name' => 'val' } )

            c.should_not == e

            e = Arachni::Element::Form.new( url: @url, inputs: { 'name' => 'val' } )
            c = Arachni::Element::Form.new( url: @url + 's', inputs: { 'name' => 'val' } )
            c.should_not == e

            e = Arachni::Element::Form.new( url: @url, inputs: { 'name' => 'val' } )
            c = Arachni::Element::Form.new( url: @url, inputs: { 'name2' => 'val' } )
            c.should_not == e
        end
    end

    describe '#dup' do
        before do
            @elem = Arachni::Element::Form.new( url: @url, inputs: { 'name' => 'val' } )
        end
        it 'duplicates the element' do
            e = @elem.dup
            e.should == @elem
            e.url = 'blah'
            e.inputs = e.inputs.merge( 'crap' => 'stuff' )
            @elem.inputs['crap'].should be_nil
            @elem.url.should == @url
        end
        it 'maintains the scope override' do
            e = @elem.dup
            e.override_instance_scope?.should be_false
            e.override_instance_scope?.should == @elem.override_instance_scope?

            e.override_instance_scope
            c = e.dup
            e.override_instance_scope?.should be_true
            c.override_instance_scope?.should == e.override_instance_scope?

            a = @elem.dup
            a.override_instance_scope
            a.override_instance_scope?.should_not == @elem.override_instance_scope?
        end
    end
end
