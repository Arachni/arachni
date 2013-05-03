require 'spec_helper'

describe Arachni::Component::Options::Address do
    before( :all ) do
        @opt = Arachni::Component::Options::Address
    end

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                @opt.new( '' ).valid?( 'localhost' ).should be_true
            end
        end
        context 'when the value is not valid' do
            it 'returns false' do
                @opt.new( '', [ true ] ).valid?( '' ).should be_false
            end
        end
        context 'when required but empty' do
            it 'returns false' do
                @opt.new( '', [true] ).valid?( nil ).should be_false
            end
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            @opt.new( '' ).type.should == 'address'
        end
    end

end
