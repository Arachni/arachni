require 'spec_helper'

describe Arachni::State::Framework do
    after(:each) do
        FileUtils.rm_rf @dump_directory if @dump_directory
    end

    subject { described_class.new }
    before(:each) { subject.clear }

    let(:page) { Factory[:page] }
    let(:url) { page.url }
    let(:dump_directory) do
        @dump_directory = "#{Dir.tmpdir}/framework-#{Arachni::Utilities.generate_token}"
    end

    describe '#rpc' do
        it "returns an instance of #{described_class::RPC}" do
            subject.rpc.should be_kind_of described_class::RPC
        end
    end

    describe '#sitemap' do
        it 'returns a Hash' do
            subject.sitemap.should be_kind_of Hash
        end
    end

    describe '#browser_skip_states' do
        it "returns a #{Arachni::Support::LookUp::HashSet}" do
            subject.browser_skip_states.should be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#update_browser_skip_states' do
        it 'updates #browser_skip_states' do
            subject.browser_skip_states.should be_empty

            set = Arachni::Support::LookUp::HashSet.new
            set << 1 << 2 << 3
            subject.update_browser_skip_states( set )
            subject.browser_skip_states.should == set
        end
    end

    describe '#page_queue' do
        it "returns an instance of #{Arachni::Support::Database::Queue}" do
            subject.page_queue.should be_kind_of Arachni::Support::Database::Queue
        end
    end

    describe '#page_queue_filter' do
        it "returns an instance of #{Arachni::Support::LookUp::HashSet}" do
            subject.page_queue_filter.should be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#push_to_page_queue' do
        it 'pushes a page to the #page_queue' do
            subject.push_to_page_queue page
        end

        it 'increments #page_queue_total_size' do
            subject.page_queue_total_size.should == 0
            subject.push_to_page_queue page
            subject.page_queue_total_size.should == 1
        end

        it 'updates the sitemap' do
            subject.should receive(:add_page_to_sitemap).with(page)
            subject.push_to_page_queue page
        end

        it 'updates #page_queue_filter' do
            subject.push_to_page_queue page
            subject.page_queue_filter.should include page
        end
    end

    describe '#page_seen?' do
        context 'when a page has already been seen' do
            it 'returns true' do
                subject.push_to_page_queue page
                subject.page_seen?( page ).should be_true
            end
        end

        context 'when a page has not been seen' do
            it 'returns false' do
                subject.page_seen?( page ).should be_false
            end
        end
    end

    describe '#page_queue_total_size' do
        it 'defaults to 0' do
            subject.page_queue_total_size.should == 0
        end
    end

    describe '#url_queue' do
        it "returns an instance of #{Arachni::Support::Database::Queue}" do
            subject.url_queue.should be_kind_of Arachni::Support::Database::Queue
        end
    end

    describe '#url_queue_filter' do
        it "returns an instance of #{Arachni::Support::LookUp::HashSet}" do
            subject.url_queue_filter.should be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#url_queue_total_size' do
        it 'defaults to 0' do
            subject.url_queue_total_size.should == 0
        end
    end

    describe '#push_to_url_queue' do
        it 'pushes a page to the #page_queue' do
            subject.push_to_url_queue url
        end

        it 'increments #url_queue_total_size' do
            subject.url_queue_total_size.should == 0
            subject.push_to_url_queue url
            subject.url_queue_total_size.should == 1
        end

        it 'updates #url_queue_filter' do
            subject.push_to_url_queue url
            subject.url_queue_filter.should include url
        end
    end

    describe '#url_seen?' do
        context 'when a URL has already been seen' do
            it 'returns true' do
                subject.push_to_url_queue url
                subject.url_seen?( url ).should be_true
            end
        end

        context 'when a page has not been seen' do
            it 'returns false' do
                subject.url_seen?( url ).should be_false
            end
        end
    end

    describe '#add_page_to_sitemap' do
        it 'updates the sitemap with the given page' do
            subject.add_page_to_sitemap page
            subject.sitemap[page.url].should == page.code
        end
    end

    describe '#dump' do
        it 'stores #rpc to disk' do
            subject.dump( dump_directory )
            described_class::RPC.load( "#{dump_directory}/rpc" ).should be_kind_of described_class::RPC
        end

        it 'stores #sitemap to disk' do
            subject.sitemap[page.url] = page.code
            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/sitemap" ) ).should == {
                page.url => page.code
            }
        end

        it 'stores #page_queue to disk' do
            subject.page_queue.max_buffer_size = 1
            subject.push_to_page_queue page
            subject.push_to_page_queue page

            subject.page_queue.buffer.should include page
            subject.page_queue.disk.size.should == 1

            subject.dump( dump_directory )

            pages = []
            Dir["#{dump_directory}/page_queue/*"].each do |page_file|
                pages << Marshal.load( IO.read( page_file ) )
            end
            pages.should == [page, page]
        end

        it 'stores #page_queue_filter to disk' do
            subject.push_to_page_queue page

            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/page_queue_filter" ) ).
                collection.should == Set.new([page.persistent_hash])
        end

        it 'stores #page_queue_total_size to disk' do
            subject.push_to_page_queue page
            subject.push_to_page_queue page
            subject.page_queue_total_size.should == 2

            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/page_queue_total_size" ) ).should == 2
        end

        it 'stores #url_queue to disk' do
            subject.push_to_url_queue url
            subject.push_to_url_queue url

            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/url_queue" ) ).should == [url, url]
        end

        it 'stores #url_queue_filter to disk' do
            subject.push_to_url_queue url

            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/url_queue_filter" ) ).
                collection.should == Set.new([url.persistent_hash])
        end

        it 'stores #url_queue_total_size to disk' do
            subject.push_to_url_queue url
            subject.push_to_url_queue url
            subject.url_queue_total_size.should == 2

            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/url_queue_total_size" ) ).should == 2
        end

        it 'stores #browser_skip_states to disk' do
            stuff = 'stuff'
            subject.browser_skip_states << stuff

            subject.dump( dump_directory )

            set = Arachni::Support::LookUp::HashSet.new( hasher: :persistent_hash)
            set << stuff

            Marshal.load( IO.read( "#{dump_directory}/browser_skip_states" ) ).should == set
        end
    end

    describe '.load' do
        it 'loads #rpc from disk' do
            subject.dump( dump_directory )
            described_class.load( dump_directory ).rpc.should be_kind_of described_class::RPC
        end

        it 'loads #sitemap from disk' do
            subject.sitemap[page.url] = page.code
            subject.dump( dump_directory )

            described_class.load( dump_directory ).sitemap.should == subject.sitemap
        end

        it 'loads #page_queue from disk' do
            subject.page_queue.max_buffer_size = 1
            subject.push_to_page_queue page
            subject.push_to_page_queue page

            subject.dump( dump_directory )

            page_queue = described_class.load( dump_directory ).page_queue
            page_queue.size.should == 2
            page_queue.pop.should == page
            page_queue.pop.should == page
        end

        it 'loads #page_queue_filter from disk' do
            subject.push_to_page_queue page

            subject.dump( dump_directory )

            described_class.load( dump_directory ).page_queue_filter.
                collection.should == Set.new([page.persistent_hash])
        end

        it 'loads #page_queue_total_size from disk' do
            subject.push_to_page_queue page
            subject.push_to_page_queue page
            subject.page_queue_total_size.should == 2

            subject.dump( dump_directory )

            described_class.load( dump_directory ).page_queue_total_size.should == 2
        end

        it 'loads #url_queue from disk' do
            subject.push_to_url_queue url
            subject.push_to_url_queue url

            subject.dump( dump_directory )

            url_queue = described_class.load( dump_directory ).url_queue
            url_queue.size.should == 2
            url_queue.pop.should == url
            url_queue.pop.should == url
        end

        it 'loads #url_queue_filter from disk' do
            subject.push_to_url_queue url
            subject.url_queue_filter.should be_any

            subject.dump( dump_directory )

            described_class.load( dump_directory ).url_queue_filter.
                collection.should == Set.new([url.persistent_hash])
        end

        it 'loads #url_queue_total_size from disk' do
            subject.push_to_url_queue url
            subject.push_to_url_queue url
            subject.url_queue_total_size.should == 2

            subject.dump( dump_directory )

            described_class.load( dump_directory ).url_queue_total_size.should == 2
        end

        it 'loads #browser_skip_states from disk' do
            stuff = 'stuff'
            subject.browser_skip_states << stuff

            subject.dump( dump_directory )

            set = Arachni::Support::LookUp::HashSet.new( hasher: :persistent_hash)
            set << stuff
            described_class.load( dump_directory ).browser_skip_states.should == set
        end
    end

    describe '#clear' do
        %w(rpc browser_skip_states sitemap page_queue page_queue_filter
            url_queue url_queue_filter).each do |method|
            it "clears ##{method}" do
                subject.send(method).should receive(:clear)
                subject.clear
            end
        end

        it 'sets #page_queue_total_size to 0' do
            subject.push_to_page_queue page
            subject.page_queue_total_size.should == 1
            subject.clear
            subject.page_queue_total_size.should == 0
        end

        it 'sets #url_queue_total_size to 0' do
            subject.push_to_url_queue page.url
            subject.url_queue_total_size.should == 1
            subject.clear
            subject.url_queue_total_size.should == 0
        end
    end
end
