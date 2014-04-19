require 'spec_helper'

describe Arachni::Component::Options::Address do
    include_examples 'component_option'

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                described_class.new( '', value: 'localhost' ).should be_true
            end
        end

        context 'when the value is not valid' do
            it 'returns false' do
                described_class.new( '', value: 'stuff' ).valid?.should be_false
            end
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            described_class.new( '' ).type.should == :address
        end
    end

end
