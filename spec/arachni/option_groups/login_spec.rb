require 'spec_helper'

describe Arachni::OptionGroups::Login do
    include_examples 'option_group'

    subject { described_class.new }
    let(:valid) do
        options = described_class.new
        options.check_url     = 'http://test.com/'
        options.check_pattern = /test/
        options
    end

    %w(check_url check_pattern).each do |method|
        it { should respond_to method }
        it { should respond_to "#{method}=" }
    end

    describe '#validate' do
        context 'when valid' do
            it 'returns nil' do
                valid.validate.should be_empty
            end
        end

        context 'when invalid' do
            context 'due to' do
                context 'missing' do
                    %w(check_url check_pattern).each do |attribute|
                        context attribute do
                            it 'returns errors' do
                                valid.send( "#{attribute}=", nil )
                                valid.validate.should ==
                                    { attribute.to_sym => 'Option is missing.'}
                            end
                        end
                    end
                end
            end
        end
    end
end
