require 'spec_helper'

describe Arachni::Component::Options::MultipleChoice do
    subject do
        described_class.new( '', description: 'Blah', choices: %w(1 2 3) )
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "includes 'choices'" do
            data['choices'].should == subject.choices
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        it "restores 'choices'" do
            restored.choices.should == subject.choices
        end
    end

    describe '#choices' do
        context 'when no values have been provided' do
            it 'returns an empty array' do
                described_class.new( '' ).choices.should == []
            end
        end

        it 'returns an array of possible, predefined, values' do
            valid_values = %w(1 2 3)
            described_class.new( '', choices: valid_values ).choices.should == valid_values
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
        it 'returns a String' do
            subject.value = '3'
            subject.normalize.should == '3'

            subject.value = 3
            subject.normalize.should == '3'
        end
    end

    describe '#description' do
        it 'returns a description including the acceptable values' do
            subject.description.include?( 'Blah' ).should be_true
            subject.choices.each { |v| subject.description.should include v }
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            subject.type.should == :multiple_choice
        end
    end

    describe '#to_h' do
        it 'includes :choices' do
            subject.to_h[:choices].should == subject.choices
        end
    end

end
