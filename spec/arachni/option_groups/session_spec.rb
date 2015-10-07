require 'spec_helper'

describe Arachni::OptionGroups::Session do
    include_examples 'option_group'

    subject { described_class.new }
    let(:valid) do
        options = described_class.new
        options.check_url     = 'http://test.com/'
        options.check_pattern = /test/
        options
    end

    %w(check_url check_pattern).each do |method|
        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end

    describe '#validate' do
        context 'when valid' do
            it 'returns nil' do
                expect(valid.validate).to be_empty
            end
        end

        context 'when invalid' do
            context 'due to' do
                context 'missing' do
                    %w(check_url check_pattern).each do |attribute|
                        context attribute do
                            it 'returns errors' do
                                valid.send( "#{attribute}=", nil )
                                expect(valid.validate).to eq(
                                    { attribute.to_sym => 'Option is missing.'}
                                )
                            end
                        end
                    end
                end
            end
        end
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "converts 'check_pattern' to strings" do
            subject.check_pattern = /test/
            expect(data['check_pattern']).to eq(subject.check_pattern.to_s)
        end
    end
end
