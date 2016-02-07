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
            expect(statistics[:rpc]).to eq(subject.rpc.statistics)
        end

        it 'includes the #sitemap size' do
            subject.add_page_to_sitemap page

            expect(statistics[:sitemap]).to eq(subject.sitemap.size)
        end

        it 'includes the #page_queue size' do
            subject.push_to_page_queue page
            expect(statistics[:page_queue]).to eq(subject.page_queue.size)
        end

        it 'includes the #page_queue_total_size' do
            subject.push_to_page_queue page
            expect(statistics[:page_queue_total_size]).to eq(subject.page_queue_total_size)
        end

        it 'includes the #url_queue size' do
            subject.push_to_url_queue url
            expect(statistics[:url_queue_total_size]).to eq(subject.url_queue_total_size)
        end

        it 'includes the #url_queue_total_size' do
            subject.push_to_url_queue page
            expect(statistics[:url_queue_total_size]).to eq(subject.url_queue_total_size)
        end
    end

    describe '#rpc' do
        it "returns an instance of #{described_class::RPC}" do
            expect(subject.rpc).to be_kind_of described_class::RPC
        end
    end

    describe '#sitemap' do
        it 'returns a Hash' do
            expect(subject.sitemap).to be_kind_of Hash
        end
    end

    describe '#page_queue' do
        it "returns an instance of #{Arachni::Support::Database::Queue}" do
            expect(subject.page_queue).to be_kind_of Arachni::Support::Database::Queue
        end
    end

    describe '#add_page_to_sitemap' do
        it 'updates the sitemap with the given page' do
            expect(subject).to receive(:update_sitemap).with( page.dom.url => page.code )
            subject.add_page_to_sitemap page
        end
    end

    describe '#update_sitemap' do
        let(:url) { 'http://stuff/' }
        let(:code) { 201 }

        it 'updates the sitemap with the given data' do
            subject.update_sitemap( url => code )
            expect(subject.sitemap[url]).to eq(code)
        end

        context "when the URL includes #{Arachni::Utilities}.random_seed" do
            let(:url) { super() + Arachni::Utilities.random_seed }

            it 'is ignored' do
                subject.update_sitemap( url => code )
                expect(subject.sitemap).not_to include url
            end
        end
    end

    describe '#push_to_page_queue' do
        it 'pushes a page to the #page_queue' do
            subject.push_to_page_queue page
        end

        it 'increments #page_queue_total_size' do
            expect(subject.page_queue_total_size).to eq(0)
            subject.push_to_page_queue page
            expect(subject.page_queue_total_size).to eq(1)
        end

        it 'updates the sitemap' do
            expect(subject).to receive(:add_page_to_sitemap).with(page)
            subject.push_to_page_queue page
        end
    end

    describe '#page_queue_total_size' do
        it 'defaults to 0' do
            expect(subject.page_queue_total_size).to eq(0)
        end
    end

    describe '#url_queue' do
        it "returns an instance of #{Arachni::Support::Database::Queue}" do
            expect(subject.url_queue).to be_kind_of Arachni::Support::Database::Queue
        end
    end

    describe '#url_queue_total_size' do
        it 'defaults to 0' do
            expect(subject.url_queue_total_size).to eq(0)
        end
    end

    describe '#push_to_url_queue' do
        it 'pushes a page to the #page_queue' do
            subject.push_to_url_queue url
        end

        it 'increments #url_queue_total_size' do
            expect(subject.url_queue_total_size).to eq(0)
            subject.push_to_url_queue url
            expect(subject.url_queue_total_size).to eq(1)
        end
    end

    describe '#dump' do
        it 'stores #rpc to disk' do
            subject.dump( dump_directory )
            expect(described_class::RPC.load( "#{dump_directory}/rpc" )).to be_kind_of described_class::RPC
        end

        it 'stores #sitemap to disk' do
            subject.sitemap[page.url] = page.code
            subject.dump( dump_directory )

            expect(Marshal.load( IO.read( "#{dump_directory}/sitemap" ) )).to eq({
                page.url => page.code
            })
        end

        it 'stores #page_queue to disk' do
            subject.page_queue.max_buffer_size = 1
            subject.push_to_page_queue page
            subject.push_to_page_queue page

            expect(subject.page_queue.buffer).to include page
            expect(subject.page_queue.disk.size).to eq(1)

            subject.dump( dump_directory )

            pages = []
            Dir["#{dump_directory}/page_queue/*"].each do |page_file|
                pages << Marshal.load( IO.binread( page_file ) )
            end
            expect(pages).to eq([page, page])
        end

        it 'stores #page_queue_total_size to disk' do
            subject.push_to_page_queue page
            subject.push_to_page_queue page
            expect(subject.page_queue_total_size).to eq(2)

            subject.dump( dump_directory )

            expect(Marshal.load( IO.read( "#{dump_directory}/page_queue_total_size" ) )).to eq(2)
        end

        it 'stores #url_queue to disk' do
            subject.push_to_url_queue url
            subject.push_to_url_queue url

            subject.dump( dump_directory )

            expect(Marshal.load( IO.read( "#{dump_directory}/url_queue" ) )).to eq([url, url])
        end

        it 'stores #url_queue_total_size to disk' do
            subject.push_to_url_queue url
            subject.push_to_url_queue url
            expect(subject.url_queue_total_size).to eq(2)

            subject.dump( dump_directory )

            expect(Marshal.load( IO.read( "#{dump_directory}/url_queue_total_size" ) )).to eq(2)
        end
    end

    describe '.load' do
        it 'loads #rpc from disk' do
            subject.dump( dump_directory )
            expect(described_class.load( dump_directory ).rpc).to be_kind_of described_class::RPC
        end

        it 'loads #sitemap from disk' do
            subject.sitemap[page.url] = page.code
            subject.dump( dump_directory )

            expect(described_class.load( dump_directory ).sitemap).to eq(subject.sitemap)
        end

        it 'loads #page_queue from disk' do
            subject.page_queue.max_buffer_size = 1
            subject.push_to_page_queue page
            subject.push_to_page_queue page

            subject.dump( dump_directory )

            page_queue = described_class.load( dump_directory ).page_queue
            expect(page_queue.size).to eq(2)
            expect(page_queue.pop).to eq(page)
            expect(page_queue.pop).to eq(page)
        end

        it 'loads #page_queue_total_size from disk' do
            subject.push_to_page_queue page
            subject.push_to_page_queue page
            expect(subject.page_queue_total_size).to eq(2)

            subject.dump( dump_directory )

            expect(described_class.load( dump_directory ).page_queue_total_size).to eq(2)
        end

        it 'loads #url_queue from disk' do
            subject.push_to_url_queue url
            subject.push_to_url_queue url

            subject.dump( dump_directory )

            url_queue = described_class.load( dump_directory ).url_queue
            expect(url_queue.size).to eq(2)
            expect(url_queue.pop).to eq(url)
            expect(url_queue.pop).to eq(url)
        end

        it 'loads #url_queue_total_size from disk' do
            subject.push_to_url_queue url
            subject.push_to_url_queue url
            expect(subject.url_queue_total_size).to eq(2)

            subject.dump( dump_directory )

            expect(described_class.load( dump_directory ).url_queue_total_size).to eq(2)
        end
    end

    describe '#clear' do
        %w(rpc sitemap page_queue url_queue).each do |method|
            it "clears ##{method}" do
                expect(subject.send(method)).to receive(:clear)
                subject.clear
            end
        end

        it 'sets #page_queue_total_size to 0' do
            subject.push_to_page_queue page
            expect(subject.page_queue_total_size).to eq(1)
            subject.clear
            expect(subject.page_queue_total_size).to eq(0)
        end

        it 'sets #url_queue_total_size to 0' do
            subject.push_to_url_queue page.url
            expect(subject.url_queue_total_size).to eq(1)
            subject.clear
            expect(subject.url_queue_total_size).to eq(0)
        end
    end
end
