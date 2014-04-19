require 'spec_helper'

describe Arachni::Component::Options::URL do
    include_examples 'component_option'
    subject { described_class.new( ' ') }

    describe '#normalize' do
        it "returns #{Arachni::URI}" do
            subject.value = 'http://localhost'
            subject.normalize.should == Arachni::URI('http://localhost')
        end
    end

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                subject.value = 'http://localhost'
                subject.valid?.should be_true
            end
        end

        context 'when the value is not valid' do
            it 'returns false' do
                ['http://localhost22', 'localhost', 11, '#$#$c3c43', true].each do |value|
                    subject.value = value
                    subject.valid?.should be_false
                end
            end
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            subject.type.should == :url
        end
    end

end
