require 'spec_helper'

describe Arachni::State do

    after( :each ) do
        described_class.reset
    end

    subject { described_class }

    describe '#issues' do
        it "returns an instance of #{described_class::Issues}" do
            subject.issues.should be_kind_of described_class::Issues
        end
    end

    describe '#audit' do
        it "returns an instance of #{described_class::Audit}" do
            subject.audit.should be_kind_of described_class::Audit
        end
    end
end
