require 'spec_helper'

describe Arachni::Component::Options::Base do

    describe '#name' do
        it 'returns the name of the option' do
            name = 'myname'
            described_class.new( name ).name.should == name.to_sym
        end
    end

    describe '#description' do
        it 'returns the description' do
            description = 'a description'
            described_class.new( '', description: description ).description.should == description
        end
    end

    describe '#default' do
        it 'returns the default value' do
            default = 'default value'
            described_class.new( '', default: default ).default.should == default
        end
    end

    describe '#required?' do
        context 'when the option is mandatory' do
            it 'returns true' do
                described_class.new( '', required: true ).required?.should be_true
            end
        end

        context 'when the option is not mandatory' do
            it 'returns false' do
                described_class.new( '', required: false ).required?.should be_false
            end
        end

        context 'by default' do
            it 'returns false' do
                described_class.new( '' ).required?.should be_false
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

    describe '#missing_value?' do
        context 'when the option is required' do
            context 'and the value is not empty' do
                it 'returns false' do
                    described_class.new( '', required: true, value: 'stuff' ).missing_value?.should be_false
                end
            end

            context 'and the value is nil' do
                it 'returns true' do
                    described_class.new( '', required: true ).missing_value?.should be_true
                end
            end
        end

        context 'when the option is not required' do
            context 'and the value is not empty' do
                it 'returns false' do
                    described_class.new( '', value: 'true' ).missing_value?.should be_false
                end
            end

            context 'and the value is empty' do
                it 'returns false' do
                    described_class.new( '' ).missing_value?.should be_false
                end
            end
        end
    end

    describe '#value=' do
        it 'sets #value' do
            option = described_class.new( '' )
            option.value = 1
            option.value.should == 1
        end
    end

    describe '#value' do
        it 'returns the set value' do
            option = described_class.new( '' )
            option.value = 1
            option.value.should == 1
        end
    end

    describe '#effective_value' do
        it 'returns the set value' do
            option = described_class.new( '' )
            option.value = 1
            option.value.should == 1
        end
    end

    %w(effective_value normalize).each do |m|
        describe "##{m}" do
            it 'returns the value as is' do
                described_class.new( '', value: 'blah' ).send(m).should == 'blah'
            end

            context 'when no #value is set' do
                it 'returns #default' do
                    described_class.new( '', default: 'test' ).send(m).should == 'test'
                end
            end
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            described_class.new( '' ).type.should == 'abstract'
        end
    end

end
