require 'spec_helper'

describe Arachni::Component::Options::Int do
    before( :all ) do
        @opt = Arachni::Component::Options::Int.new( '' )
    end

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                @opt.valid?( '1' ).should be_true
                @opt.valid?( 1 ).should be_true
                @opt.valid?( 0 ).should be_true
                @opt.valid?( '0' ).should be_true
                @opt.valid?( '0xdd' ).should be_true
            end
        end
        context 'when the value is not valid' do
            it 'returns false' do
                @opt.valid?( 'sd' ).should be_false
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
            @opt.normalize( '0xdd' ).should == 221
            @opt.normalize( '5dd' ).should be_nil
            @opt.normalize( '5' ).should == 5
            @opt.normalize( 3 ).should == 3
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            @opt.type.should == 'integer'
        end
    end

end
