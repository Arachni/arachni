require 'spec_helper'

describe Arachni::Component::Options::Path do
    include_examples 'component_option'
    subject { described_class.new( '' ) }

    describe '#valid?' do
        context 'when the path exists' do
            it 'returns true' do
                subject.value = __FILE__
                expect(subject.valid?).to be_truthy
            end
        end

        context 'when the path does not exist' do
            it 'returns false' do
                subject.value = __FILE__ + '22'
                expect(subject.valid?).to be_falsey
            end
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            expect(subject.type).to eq(:path)
        end
    end

end
