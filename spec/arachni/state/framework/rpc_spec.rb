require 'spec_helper'

describe Arachni::State::Framework::RPC do
    subject { described_class.new }
    before(:each) { subject.clear }
    after(:each) do
        FileUtils.rm_rf @dump_directory if @dump_directory
    end

    let(:dump_directory) do
        @dump_directory = "#{Dir.tmpdir}/rpc-#{Arachni::Utilities.generate_token}"
    end
    let(:page) { Factory[:page] }
    let(:url) { page.url }

    describe '#distributed_pages' do
        it "returns an instance of #{Arachni::Support::LookUp::HashSet}" do
            expect(subject.distributed_pages).to be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#distributed_elements' do
        it "returns an instance of #{Set}" do
            expect(subject.distributed_elements).to be_kind_of Set
        end
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        it 'includes the size of #distributed_pages' do
            subject.distributed_pages << url
            expect(statistics[:distributed_pages]).to eq(subject.distributed_pages.size)
        end

        it 'includes the size of #distributed_elements' do
            subject.distributed_elements << url.persistent_hash
            expect(statistics[:distributed_elements]).to eq(subject.distributed_elements.size)
        end
    end

    describe '#dump' do
        it 'stores #distributed_pages to disk' do
            subject.distributed_pages << url
            subject.dump( dump_directory )

            expect(Marshal.load( IO.read( "#{dump_directory}/distributed_pages" ) ).
                collection).to eq(Set.new([url.persistent_hash]))
        end

        it 'stores #distributed_elements to disk' do
            subject.distributed_elements << url.persistent_hash
            subject.dump( dump_directory )

            expect(Marshal.load( IO.read( "#{dump_directory}/distributed_elements" ) )).to eq(Set.new([url.persistent_hash]))
        end
    end

    describe '.load' do
        it 'loads #distributed_pages from disk' do
            subject.distributed_pages << url
            subject.dump( dump_directory )

            expect(described_class.load( dump_directory ).distributed_pages.
                collection).to eq(Set.new([url.persistent_hash]))
        end

        it 'loads #distributed_elements from disk' do
            subject.distributed_elements << url.persistent_hash
            subject.dump( dump_directory )

            expect(described_class.load( dump_directory ).distributed_elements).
                to eq(Set.new([url.persistent_hash]))
        end
    end

    describe '#clear' do
        %w(distributed_pages distributed_elements).each do |method|
            it "clears ##{method}" do
                expect(subject.send(method)).to receive(:clear)
                subject.clear
            end
        end
    end
end
