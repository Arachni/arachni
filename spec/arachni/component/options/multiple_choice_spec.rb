require 'spec_helper'

describe Arachni::Component::Options::MultipleChoice do
    subject do
        described_class.new( '', description: 'Blah', choices: %w(1 2 3) )
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "includes 'choices'" do
            expect(data['choices']).to eq(subject.choices)
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        it "restores 'choices'" do
            expect(restored.choices).to eq(subject.choices)
        end
    end

    describe '#choices' do
        context 'when no values have been provided' do
            it 'returns an empty array' do
                expect(described_class.new( '' ).choices).to eq([])
            end
        end

        it 'returns an array of possible, predefined, values' do
            valid_values = %w(1 2 3)
            expect(described_class.new( '', choices: valid_values ).choices).to eq(valid_values)
        end
    end

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                subject.value = 1
                expect(subject).to be_truthy
            end
        end
        context 'when the value is not valid' do
            it 'returns false' do
                subject.value = 4
                expect(subject.valid?).to be_falsey
            end
        end
    end

    describe '#normalize' do
        it 'returns a String' do
            subject.value = '3'
            expect(subject.normalize).to eq('3')

            subject.value = 3
            expect(subject.normalize).to eq('3')
        end
    end

    describe '#description' do
        it 'returns a description including the acceptable values' do
            expect(subject.description.include?( 'Blah' )).to be_truthy
            subject.choices.each { |v| expect(subject.description).to include v }
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            expect(subject.type).to eq(:multiple_choice)
        end
    end

    describe '#to_h' do
        it 'includes :choices' do
            expect(subject.to_h[:choices]).to eq(subject.choices)
        end
    end

end
