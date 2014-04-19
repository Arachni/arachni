require 'spec_helper'

describe Arachni::Component::Options::Path do
    include_examples 'component_option'
    subject { described_class.new( '' ) }

    describe '#valid?' do
        context 'when the path exists' do
            it 'returns true' do
                subject.value = __FILE__
                subject.valid?.should be_true
            end
        end

        context 'when the path does not exist' do
            it 'returns false' do
                subject.value = __FILE__ + '22'
                subject.valid?.should be_false
            end
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            subject.type.should == :path
        end
    end

end
