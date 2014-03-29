require 'spec_helper'

describe Arachni::State do
    after(:each) do
        FileUtils.rm_rf @dump_archive if @dump_archive
    end
    after( :each ) do
        described_class.reset
    end

    subject { described_class }
    let(:dump_archive) do
        @dump_archive = "#{Dir.tmpdir}/state-#{Arachni::Utilities.generate_token}.zip"
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
                previous_instance = subject.send(name)

                subject.dump( dump_archive )

                new_instance = subject.load( dump_archive ).send(name)

                new_instance.should be_kind_of subject.send(name).class
                new_instance.object_id.should_not == previous_instance.object_id
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
