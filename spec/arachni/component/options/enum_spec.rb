require 'spec_helper'

describe Arachni::Component::Options::Enum do
    before( :all ) do
        @opt = Arachni::Component::Options::Enum.new( '', [ false, 'Blah', nil, %w(1 2 3)] )
    end

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                @opt.valid?( '1' ).should be_true
            end
        end
        context 'when the value is not valid' do
            it 'returns false' do
                @opt.valid?( '4' ).should be_false
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
            @opt.normalize( '5' ).should be_nil
            @opt.normalize( '3' ).should == '3'
            @opt.normalize( 3 ).should == '3'
        end
    end

    describe '#desc' do
        it 'returns a description including the acceptable values' do
            @opt.desc.include?( 'Blah' ).should be_true
            @opt.enums.each { |v| @opt.desc.include?( v ).should be_true }

            @opt.desc = 'boo'
            @opt.desc.include?( 'boo' ).should be_true
            @opt.desc.include?( 'Blah' ).should be_false
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            @opt.type.should == 'enum'
        end
    end

end
