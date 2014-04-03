require 'spec_helper'

describe Arachni::Data do
    after(:each) do
        FileUtils.rm_rf @dump_directory if @dump_directory
    end
    after( :each ) do
        described_class.reset
    end

    subject { described_class }
    let(:dump_directory) do
        @dump_directory = "#{Dir.tmpdir}/data-#{Arachni::Utilities.generate_token}/"
    end

    describe '#framework' do
        it "returns an instance of #{described_class::Framework}" do
            subject.framework.should be_kind_of described_class::Framework
        end
    end

    describe '#issues' do
        it "returns an instance of #{described_class::Issues}" do
            subject.issues.should be_kind_of described_class::Issues
        end
    end

    describe '#plugins' do
        it "returns an instance of #{described_class::Plugins}" do
            subject.plugins.should be_kind_of described_class::Plugins
        end
    end

    describe '#statistics' do
        %w(framework issues plugins).each do |name|
            it "includes :#{name} statistics" do
                subject.statistics[name.to_sym].should == subject.send(name).statistics
            end
        end
    end

    describe '.dump' do
        %w(framework issues plugins).each do |name|
            it "stores ##{name} to disk" do
                previous_instance = subject.send(name)

                subject.dump( dump_directory )

                new_instance = subject.load( dump_directory ).send(name)

                new_instance.should be_kind_of subject.send(name).class
                new_instance.object_id.should_not == previous_instance.object_id
            end
        end
    end

    describe '#clear' do
        %w(framework issues plugins).each do |method|
            it "clears ##{method}" do
                subject.send(method).should receive(:clear)
                subject.clear
            end
        end
    end
end
