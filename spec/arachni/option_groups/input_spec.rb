require 'spec_helper'

describe Arachni::OptionGroups::Input do
    include_examples 'option_group'
    subject { described_class.new }

    %w(values without_defaults).each do |method|
        it { should respond_to method }
        it { should respond_to "#{method}=" }
    end

    context '#values' do
        it 'converts the keys to Regexp' do
            subject.values = {
                'article' => 'my article'
            }

            subject.values.should == {
                /article/ => 'my article'
            }
        end
    end

    context '#default_values' do
        it 'converts the keys to Regexp' do
            subject.default_values = {
                'article' => 'my article'
            }

            subject.default_values.should == {
                /article/ => 'my article'
            }
        end
    end

    context '#without_defaults' do
        it 'returns false' do
            subject.without_defaults.should be_false
        end
    end

    describe '#effective_values' do
        it 'merges the #default_values with the configured #values' do
            subject.values = { /some stuff/ => '2' }
            subject.effective_values.should ==
                subject.default_values.merge( subject.values )
        end

        context '#without_defaults?' do
            it 'ignores default values' do
                subject.without_defaults = true

                subject.values = { /some stuff/ => '2' }
                subject.effective_values.should == subject.values
            end
        end
    end

    describe '#update_values_from_file' do
        it 'updates #values from the given file'
    end

    describe '#value_for_name' do
        it 'returns the value that matches the given name'
    end

    describe '#fill' do
        let(:inputs) { { 'name' => 'john' } }

        it 'fills in all empty inputs' do
            subject.fill(
                'nAMe'    => nil,
                'usEr'    => nil,
                'uSR'     => nil,
                'pAsS'    => nil,
                'tXt'     => nil,
                'nUm'     => nil,
                'AmoUnt'  => nil,
                'mAIL'    => nil,
                'aCcouNt' => nil,
                'iD'      => nil
            ).should == {
                'nAMe'    => 'arachni_name',
                'usEr'    => 'arachni_user',
                'uSR'     => 'arachni_user',
                'pAsS'    => '5543!%arachni_secret',
                'tXt'     => 'arachni_text',
                'nUm'     => '132',
                'AmoUnt'  => '100',
                'mAIL'    => 'arachni@email.gr',
                'aCcouNt' => '12',
                'iD'      => '1'
            }
        end

        context 'when there is a value' do
            it 'skips it' do
                subject.fill( inputs ).should == inputs
            end

            context '#force?' do
                it 'overwrites it' do
                    subject.force = true
                    subject.fill( inputs ).should == { 'name' => 'arachni_name' }
                end
            end
        end
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "converts 'values' to strings" do
            values = { /article/ => 'my article' }
            subject.values = values

            data['values'].should == { 'article' => 'my article' }
        end

        it "converts 'default_values' to strings" do
            data['default_values'].keys.should ==
                subject.default_values.keys.map(&:source)
        end
    end

end
