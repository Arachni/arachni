require 'spec_helper'

describe Arachni::Component::Options::Port do
    include_examples 'component_option'
    subject { described_class.new( '' ) }

    describe '#valid?' do
        context 'when the path exists' do
            it 'returns true' do
                (1..65535).each do |p|
                    subject.value = p
                    subject.valid?.should be_true

                    subject.value = p.to_s
                    subject.valid?.should be_true
                end
            end
        end
        context 'when the path does not exist' do
            it 'returns false' do
                ['dd', -1, 0, 9999999].each do |p|
                    subject.value = p
                    subject.valid?.should be_false

                    subject.value = p.to_s
                    subject.valid?.should be_false
                end

            end
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            subject.type.should == :port
        end
    end

end
