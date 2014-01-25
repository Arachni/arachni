require 'spec_helper'

describe Arachni::BrowserCluster::Job::Result do
    let(:job) { Factory[:custom_job] }
    subject { described_class.new }
    it { should respond_to :job }
    it { should respond_to :job= }

    describe '#initialize' do
        it 'sets the given data via accessors' do
            described_class.new( job: job ).job.id.should == job.id
        end
    end
end
