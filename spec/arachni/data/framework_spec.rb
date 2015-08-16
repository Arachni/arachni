require 'spec_helper'

describe Arachni::Data::Framework do
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

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        it "includes #{described_class::RPC}#statistics" do
            statistics[:rpc].should == subject.rpc.statistics
        end

        it 'includes the #sitemap size' do
            subject.add_page_to_sitemap page

            statistics[:sitemap].should == subject.sitemap.size
        end

        it 'includes the #page_queue size' do
            subject.push_to_page_queue page
            statistics[:page_queue].should == subject.page_queue.size
        end

        it 'includes the #page_queue_total_size' do
            subject.push_to_page_queue page
            statistics[:page_queue_total_size].should == subject.page_queue_total_size
        end

        it 'includes the #url_queue size' do
            subject.push_to_url_queue url
            statistics[:url_queue_total_size].should == subject.url_queue_total_size
        end

        it 'includes the #url_queue_total_size' do
            subject.push_to_url_queue page
            statistics[:url_queue_total_size].should == subject.url_queue_total_size
        end
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

    describe '#page_queue' do
        it "returns an instance of #{Arachni::Support::Database::Queue}" do
            subject.page_queue.should be_kind_of Arachni::Support::Database::Queue
        end
    end

    describe '#add_page_to_sitemap' do
        it 'updates the sitemap with the given page' do
            subject.should receive(:update_sitemap).with( page.dom.url => page.code )
            subject.add_page_to_sitemap page
        end
    end

    describe '#update_sitemap' do
        let(:url) { 'http://stuff/' }
        let(:code) { 201 }

        it 'updates the sitemap with the given data' do
            subject.update_sitemap( url => code )
            subject.sitemap[url].should == code
        end

        context "when the URL includes #{Arachni::Utilities}.random_seed" do
            let(:url) { super() + Arachni::Utilities.random_seed }

            it 'is ignored' do
                subject.update_sitemap( url => code )
                subject.sitemap.should_not include url
            end
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

        it 'stores #url_queue_total_size to disk' do
            subject.push_to_url_queue url
            subject.push_to_url_queue url
            subject.url_queue_total_size.should == 2

            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/url_queue_total_size" ) ).should == 2
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

        it 'loads #url_queue_total_size from disk' do
            subject.push_to_url_queue url
            subject.push_to_url_queue url
            subject.url_queue_total_size.should == 2

            subject.dump( dump_directory )

            described_class.load( dump_directory ).url_queue_total_size.should == 2
        end
    end

    describe '#clear' do
        %w(rpc sitemap page_queue url_queue).each do |method|
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
