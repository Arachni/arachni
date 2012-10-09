require_relative '../../spec_helper'

describe Arachni::Element::Base do
    before( :all ) do
        @utils=  Arachni::Module::Utilities
        @url = @utils.normalize_url( 'http://test.com' )
        @raw = { raw: { hash: 'stuff' } }
        @e = Arachni::Element::Base.new( @url, @raw )
    end

    it 'should have the assigned URL' do
        @e.url.should == @url
    end

    it 'should have the assigned raw data' do
        @e.raw.should == @raw
    end

    describe '#url=' do
        it 'should normalize the passed URL' do
            e = Arachni::Element::Base.new( @url, @raw )
            url = 'http://test.com/some stuff#frag!'
            e.url = url
            e.url.should == @utils.normalize_url( url )
        end
    end

    describe '#action=' do
        it 'should normalize the passed URL' do
            e = Arachni::Element::Base.new( @url, @raw )
            url = 'http://test.com/some stuff#frag!'
            e.action = url
            e.action.should == @utils.normalize_url( url )
        end

        it 'should convert the passed URL to absolute' do
            e = Arachni::Element::Base.new( @url, @raw )
            url = 'some stuff#frag!'
            e.action = url
            e.action.should == @utils.to_absolute( url, @url )
        end
    end

    describe '#==' do
        it 'should assert equality based on method, action and inputs' do
            e = Arachni::Element::Link.new( @url, inputs: { 'name' => 'val' } )
            c = Arachni::Element::Link.new( @url, inputs: { 'name' => 'val' } )
            c.should == e

            e = Arachni::Element::Form.new( @url, inputs: { 'name' => 'val' } )
            c = Arachni::Element::Form.new( @url, inputs: { 'name' => 'val' } )
            c.should == e

            e = Arachni::Element::Form.new( @url, method: 'post', inputs: { 'name' => 'val' } )
            c = Arachni::Element::Form.new( @url, method: 'post', inputs: { 'name' => 'val' } )
            c.should == e

            e = Arachni::Element::Form.new( @url, inputs: { 'name' => 'val' } )
            c = Arachni::Element::Form.new( @url, method: 'post', inputs: { 'name' => 'val' } )

            c.should_not == e

            e = Arachni::Element::Form.new( @url, inputs: { 'name' => 'val' } )
            c = Arachni::Element::Form.new( @url + 's', inputs: { 'name' => 'val' } )
            c.should_not == e

            e = Arachni::Element::Form.new( @url, inputs: { 'name' => 'val' } )
            c = Arachni::Element::Form.new( @url, inputs: { 'name2' => 'val' } )
            c.should_not == e
        end
    end

    describe '#dup' do
        before do
            @elem = Arachni::Element::Link.new( @url, inputs: { 'name' => 'val' } )
        end
        it 'should duplicate the element' do
            e = @elem.dup
            e.should == @elem
            e.url = 'blah'
            e.auditable = e.auditable.merge( 'crap' => 'stuff' )
            @elem.auditable['crap'].should be_nil
            @elem.url.should == @url
        end
        it 'should maintain the scope override' do
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

    describe '#hash' do
        context 'when the #method is updated' do
            it 'should be updated too' do
                e = Arachni::Element::Base.new( @url, @raw )
                h = e.hash
                e.method = 'get'
                e.hash.should_not == h
            end
        end
        context 'when the #action is updated' do
            it 'should be updated too' do
                e = Arachni::Element::Base.new( @url, @raw )
                h = e.hash
                e.action = 'http://stuff.com'
                e.hash.should_not == h
            end
        end
        context 'when the #auditable is updated' do
            it 'should be updated too' do
                e = Arachni::Element::Base.new( @url, @raw )
                h = e.hash
                e.auditable = { 'stuff' => 'blah' }
                e.hash.should_not == h
            end
        end
    end
end
