require 'spec_helper'

describe Arachni::Component::Options::Enum do
    subject do
        described_class.new( '', description: 'Blah', valid_values: %w(1 2 3) )
    end

    describe '#valid_values' do
        context 'when no values have been provided' do
            it 'returns an empty array' do
                described_class.new( '' ).valid_values.should == []
            end
        end

        it 'returns an array of possible, predefined, values' do
            valid_values = %w(1 2 3)
            described_class.new( '', valid_values: valid_values ).valid_values.should == valid_values
        end
    end

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                subject.value = 1
                subject.should be_true
            end
        end
        context 'when the value is not valid' do
            it 'returns false' do
                subject.value = 4
                subject.valid?.should be_false
            end
        end
    end

    describe '#normalize' do
        it 'converts the string input into a boolean value' do
            subject.value = '3'
            subject.normalize.should == '3'

            subject.value = 3
            subject.normalize.should == '3'
        end
    end

    describe '#description' do
        it 'returns a description including the acceptable values' do
            subject.description.include?( 'Blah' ).should be_true
            subject.valid_values.each { |v| subject.description.should include v }
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            subject.type.should == 'enum'
        end
    end

end
