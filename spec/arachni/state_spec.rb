require 'spec_helper'

describe Arachni::State do
    after(:each) do
        FileUtils.rm_rf @dump_directory if @dump_directory
    end
    after( :each ) do
        described_class.reset
    end

    subject { described_class }
    let(:dump_directory) do
        @dump_directory = "#{Dir.tmpdir}/state-#{Arachni::Utilities.generate_token}"
    end

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

    describe '#dump' do
        [:issues, :plugins, :audit, :element_filter, :framework].each do |name|
            it "stores ##{name} to disk" do
                subject.dump( dump_directory )
                subject.send(name).class.load( "#{dump_directory}/#{name}" ).should be_kind_of subject.send(name).class
            end
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
