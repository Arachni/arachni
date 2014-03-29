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
            subject.distributed_pages.should be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#distributed_elements' do
        it "returns an instance of #{Set}" do
            subject.distributed_elements.should be_kind_of Set
        end
    end

    describe '#distributed_page_queue' do
        it "returns an instance of #{Arachni::Support::Database::Queue}" do
            subject.distributed_page_queue.should be_kind_of Arachni::Support::Database::Queue
        end
    end

    describe '#dump' do
        it 'stores #distributed_page_queue to disk' do
            subject.distributed_page_queue.max_buffer_size = 1
            subject.distributed_page_queue << page
            subject.distributed_page_queue << page

            subject.distributed_page_queue.buffer.should include page
            subject.distributed_page_queue.disk.size.should == 1

            subject.dump( dump_directory )

            pages = []
            Dir["#{dump_directory}/distributed_page_queue/*"].each do |page_file|
                pages << Marshal.load( IO.read( page_file ) )
            end
            pages.should == [page, page]
        end

        it 'stores #distributed_pages to disk' do
            subject.distributed_pages << url
            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/distributed_pages" ) ).
                collection.should == Set.new([url.persistent_hash])
        end

        it 'stores #distributed_elements to disk' do
            subject.distributed_elements << url.persistent_hash
            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/distributed_elements" ) ).should == Set.new([url.persistent_hash])
        end
    end

    describe '.load' do
        it 'loads #distributed_page_queue from disk' do
            subject.distributed_page_queue.max_buffer_size = 1
            subject.distributed_page_queue << page
            subject.distributed_page_queue << page

            subject.dump( dump_directory )

            page_queue = described_class.load( dump_directory ).distributed_page_queue
            page_queue.size.should == 2
            page_queue.pop.should == page
            page_queue.pop.should == page
        end

        it 'loads #distributed_pages from disk' do
            subject.distributed_pages << url
            subject.dump( dump_directory )

            described_class.load( dump_directory ).distributed_pages.
                collection.should == Set.new([url.persistent_hash])
        end

        it 'loads #distributed_elements from disk' do
            subject.distributed_elements << url.persistent_hash
            subject.dump( dump_directory )

            described_class.load( dump_directory ).distributed_elements.
                should == Set.new([url.persistent_hash])
        end
    end

    describe '#clear' do
        %w(distributed_pages distributed_elements distributed_page_queue).each do |method|
            it "clears ##{method}" do
                subject.send(method).should receive(:clear)
                subject.clear
            end
        end
    end
end
