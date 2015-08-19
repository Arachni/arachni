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

    describe '#audit' do
        it "returns an instance of #{described_class::Audit}" do
            expect(subject.audit).to be_kind_of described_class::Audit
        end
    end

    describe '#element_filter' do
        it "returns an instance of #{described_class::ElementFilter}" do
            expect(subject.element_filter).to be_kind_of described_class::ElementFilter
        end
    end

    describe '#framework' do
        it "returns an instance of #{described_class::Framework}" do
            expect(subject.framework).to be_kind_of described_class::Framework
        end
    end

    describe '#options' do
        it "returns an instance of #{described_class::Options}" do
            expect(subject.options).to be_kind_of described_class::Options
        end
    end

    describe '#http' do
        it "returns an instance of #{described_class::HTTP}" do
            expect(subject.http).to be_kind_of described_class::HTTP
        end
    end

    describe '#plugins' do
        it "returns an instance of #{described_class::Plugins}" do
            expect(subject.plugins).to be_kind_of described_class::Plugins
        end
    end

    describe '#session' do
        it "returns an instance of #{described_class}::Session"
    end

    describe '#statistics' do
        %w(options audit element_filter framework http plugins).each do |name|
            it "includes :#{name} statistics" do
                expect(subject.statistics[name.to_sym]).to eq(subject.send(name).statistics)
            end
        end
    end

    describe '.dump' do
        %w(options audit element_filter framework http plugins).each do |name|
            it "stores ##{name} to disk" do
                previous_instance = subject.send(name)

                subject.dump( dump_directory )

                new_instance = subject.load( dump_directory ).send(name)

                expect(new_instance).to be_kind_of subject.send(name).class
                expect(new_instance.object_id).not_to eq(previous_instance.object_id)
            end
        end
    end

    describe '#clear' do
        %w(options audit element_filter framework http plugins).each do |method|
            it "clears ##{method}" do
                expect(subject.send(method)).to receive(:clear)
                subject.clear
            end
        end
    end
end
