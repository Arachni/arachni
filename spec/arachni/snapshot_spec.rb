require 'spec_helper'

describe Arachni::Snapshot do
    after(:each) do
        FileUtils.rm_rf @dump_archive if @dump_archive
    end

    subject { described_class }
    let(:dump_archive) do
        @dump_archive = "#{Dir.tmpdir}/snapshot-#{Arachni::Utilities.generate_token}.afs"
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
