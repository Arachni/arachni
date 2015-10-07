require 'spec_helper'

describe Arachni::OptionGroups::BrowserCluster do
    include_examples 'option_group'
    subject { described_class.new }

    %w(pool_size job_timeout worker_time_to_live ignore_images screen_width
        screen_height local_storage).each do |method|
        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end

    describe '#local_storage' do
        context 'when passed a Hash' do
            it 'sets it' do
                subject.local_storage = { 1 => 2 }
                expect(subject.local_storage).to eq({ 1 => 2 })
            end
        end

        context 'when passed anything other than Hash' do
            it 'raises ArgumentError' do
                expect do
                    subject.local_storage = 1
                end.to raise_error ArgumentError
            end
        end
    end
end
