require 'spec_helper'

describe Arachni::State::Framework do
    subject { described_class.new }
    before(:each) { subject.clear }

    let(:page) { Factory[:page] }
    let(:url) { page.url }

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
        it 'returns a Set' do
            subject.browser_skip_states.should be_kind_of Set
        end
    end

    describe '#update_browser_skip_states' do
        it 'updates #browser_skip_states' do
            subject.browser_skip_states.should be_empty

            set = Set.new([1,2,3])
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
        it "returns an instance of #{Queue}" do
            subject.url_queue.should be_kind_of Queue
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
