require 'spec_helper'

describe Arachni::Component::Options::Int do
    subject { described_class.new( '' ) }

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                ['1', 1, 0, '0'].each do |value|
                    subject.value = value
                    subject.valid?.should be_true
                end
            end
        end

        context 'when the value is not valid' do
            it 'returns false' do
                %w(sd 4d).each do |value|
                    subject.value = value
                    subject.valid?.should be_false
                end
            end
        end
    end

    describe '#normalize' do
        it 'converts the string input into a boolean value' do
            subject.value = '5'
            subject.normalize.should == 5

            subject.value = 3
            subject.normalize.should == 3
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            subject.type.should == 'integer'
        end
    end

end
