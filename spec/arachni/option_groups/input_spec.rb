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
        let(:file) { "#{fixtures_path}option_groups/input.yml" }

        it 'updates #values from the given file' do
            subject.update_values_from_file( file )
            subject.values.should == {
                /test/       => 'blah',
                /other-test/ => 'blah2'
            }
        end
    end

    describe '#value_for_name' do
        it 'returns the value that matches the given name' do
            subject.without_defaults = true
            subject.values = { /name/ => 'John Doe' }

            subject.value_for_name( 'name' ).should == 'John Doe'
        end

        context 'when no match could be found' do
            context "and 'use_default' is set to" do
                context true do
                    it 'returns the default' do
                        subject.value_for_name( 'blahblah', true ).should ==
                            described_class::DEFAULT
                    end
                end

                context false do
                    it 'returns nil' do
                        subject.value_for_name( 'blahblah', false ).should == nil
                    end
                end

                context 'by default' do
                    it 'returns the default' do
                        subject.value_for_name( 'blahblah' ).should ==
                            described_class::DEFAULT
                    end
                end
            end
        end
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
                'stuff'   => 'stuff value',
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
                'stuff'   => 'stuff value',
                'iD'      => '1'
            }
        end

        context 'when no match could be found' do
            let(:inputs) { { 'stuff' => '' } }

            it 'does not overwrite it' do
                subject.fill( inputs ).should == {
                    'stuff' => described_class::DEFAULT
                }
            end
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

                context 'when no value could be found' do
                    let(:inputs) { { 'stuff' => 'test' } }

                    it 'does not overwrite it' do
                        subject.force = true
                        subject.fill( inputs ).should == inputs
                    end
                end
            end
        end
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "converts 'values' to strings" do
            values = { /article/ => 'my article' }
            subject.values = values

            data['values'].should == { /article/.to_s => 'my article' }
        end

        it "converts 'default_values' to strings" do
            data['default_values'].keys.should ==
                subject.default_values.keys.map(&:to_s)
        end
    end

end
