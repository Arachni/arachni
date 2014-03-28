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

    describe '#element_filter' do
        it "returns an instance of #{described_class::ElementFilter}" do
            subject.element_filter.should be_kind_of described_class::ElementFilter
        end
    end

    describe '#framework' do
        it "returns an instance of #{described_class::Framework}" do
            subject.framework.should be_kind_of described_class::Framework
        end
    end

    describe '#clear' do
        %w(issues audit element_filter framework).each do |method|
            it "clears ##{method}" do
                subject.send(method).should receive(:clear)
                subject.clear
            end
        end
    end
end
