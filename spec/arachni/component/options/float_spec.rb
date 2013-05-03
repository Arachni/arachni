require 'spec_helper'

describe Arachni::Component::Options::Float do
    before( :all ) do
        @opt = Arachni::Component::Options::Float.new( '' )
    end

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                @opt.valid?( '1' ).should be_true
                @opt.valid?( 1 ).should be_true
                @opt.valid?( 1.2 ).should be_true
            end
        end
        context 'when the value is not valid' do
            it 'returns false' do
                @opt.valid?( '4d' ).should be_false
            end
        end
        context 'when required but empty' do
            it 'returns false' do
                @opt.class.new( '', [true] ).valid?( nil ).should be_false
            end
        end
    end

    describe '#normalize' do
        it 'converts the string input into a boolean value' do
            @opt.normalize( '5' ).should == 5.0
            @opt.normalize( '5.3' ).should == 5.3
            @opt.normalize( 3 ).should == 3.0
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            @opt.type.should == 'float'
        end
    end

end
