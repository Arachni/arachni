require 'spec_helper'

describe Arachni::Component::Options::Base do
    include_examples 'component_option'

    describe '#normalize' do
        it 'returns the value as is' do
            described_class.new( '', value: 'blah' ).normalize.should == 'blah'
        end

        context 'when no #value is set' do
            it 'returns #default' do
                described_class.new( '', default: 'test' ).normalize.should == 'test'
            end
        end
    end

    describe '#valid?' do
        context 'when the option is required' do
            context 'and the value is not empty' do
                it 'returns true' do
                    described_class.new( '', required: true, value: 'stuff' ).valid?.should be_true
                end
            end

            context 'and the value is nil' do
                it 'returns false' do
                    described_class.new( '', required: true ).valid?.should be_false
                end
            end
        end

        context 'when the option is not required' do
            context 'and the value is not empty' do
                it 'returns true' do
                    described_class.new( '', value: 'true' ).valid?.should be_true
                end
            end

            context 'and the value is empty' do
                it 'returns true' do
                    described_class.new( '' ).valid?.should be_true
                end
            end
        end
    end

    describe '#type' do
        it 'returns the option type' do
            described_class.new( '' ).type.should == :abstract
        end
    end
end
