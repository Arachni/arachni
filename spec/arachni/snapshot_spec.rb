require 'spec_helper'

describe Arachni::Snapshot do
    after(:each) do
        subject.reset
        FileUtils.rm_rf @dump_archive if @dump_archive
    end

    subject { described_class }
    let(:dump_archive) do
        @dump_archive = "#{Dir.tmpdir}/snapshot-#{Arachni::Utilities.generate_token}.afs"
    end

    describe '.summary' do
        let(:summary) { subject.summary }

        it 'includes :data' do
            summary[:data].should == Arachni::Data.statistics
        end

        it 'includes :state' do
            summary[:state].should == Arachni::State.statistics
        end
    end

    describe '.metadata' do
        context 'when dealing with a restored snapshot' do
            it 'returns the stored metadata from the snapshot archive' do
                subject.dump( dump_archive )
                subject.load( dump_archive )

                subject.metadata.should == subject.read_metadata( dump_archive )
            end
        end

        context 'when not dealing with a restored snapshot' do
            it 'returns nil' do
                subject.metadata.should be_nil
            end
        end
    end

    describe '.restored?' do
        context 'when dealing with a restored snapshot' do
            it 'returns true' do
                subject.dump( dump_archive )
                subject.load( dump_archive )

                subject.should be_restored
            end
        end

        context 'when not dealing with a restored snapshot' do
            it 'returns false' do
                subject.should_not be_restored
            end
        end
    end

    describe '.location' do
        context 'when dealing with a restored snapshot' do
            it 'returns the location of the loaded snapshot' do
                subject.dump( dump_archive )
                subject.load( dump_archive )

                subject.location.should == dump_archive
            end
        end

        context 'when not dealing with a restored snapshot' do
            it 'returns nil' do
                subject.location.should be_nil
            end
        end
    end

    describe '.read_metadata' do
        let(:metadata) do
            subject.dump( dump_archive )
            subject.read_metadata( dump_archive )
        end

        it 'includes a :timestamp' do
            metadata[:timestamp].should be_kind_of Time
        end

        it 'includes a :version' do
            metadata[:version].should == Arachni::VERSION
        end

        it 'includes a #summary' do
            metadata[:summary].should == subject.summary
        end
    end

    describe '.dump' do
        it "stores #{Arachni::State} to disk" do
            Arachni::State.should receive(:dump)
            Arachni::Data.should receive(:dump)

            subject.dump( dump_archive )
        end
    end

    describe '.load' do
        it "stores #{Arachni::State} to disk" do
            subject.dump( dump_archive )

            Arachni::State.should receive(:load)
            Arachni::Data.should receive(:load)

            subject.load( dump_archive )
        end
    end
end
