require 'spec_helper'

describe Arachni::BrowserCluster::Job::Result do
    let(:job) { Factory[:custom_job] }
    subject { described_class.new }
    it { is_expected.to respond_to :job }
    it { is_expected.to respond_to :job= }

    describe '#initialize' do
        it 'sets the given data via accessors' do
            expect(described_class.new( job: job ).job.id).to eq(job.id)
        end
    end
end
