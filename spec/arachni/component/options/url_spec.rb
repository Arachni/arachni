require 'spec_helper'

describe Arachni::Component::Options::URL do
    before( :all ) do
        @opt = Arachni::Component::Options::URL.new( ' ')
    end

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                @opt.valid?( 'http://localhost' ).should be_true
            end
        end
        context 'when the value is not valid' do
            it 'returns false' do
                @opt.valid?( 'http://localhost22' ).should be_false
                @opt.valid?( 'localhost' ).should be_false
                @opt.valid?( 11 ).should be_false
                @opt.valid?( '#$#$c3c43' ).should be_false
                @opt.valid?( true ).should be_false
            end
        end
        context 'when required but empty' do
            it 'returns false' do
                @opt.class.new( '', [true] ).valid?( nil ).should be_false
            end
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            @opt.type.should == 'url'
        end
    end

end
