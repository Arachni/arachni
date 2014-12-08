require 'spec_helper'

describe Arachni::Framework::Parts::Data do
    include_examples 'framework'

    describe '#data' do
        it "returns #{Arachni::Data::Framework}" do
            subject.data.should be_kind_of Arachni::Data::Framework
        end
    end

    describe '#sitemap' do
        it 'returns a hash with covered URLs and HTTP status codes' do
            Arachni::Framework.new do |f|
                f.options.url = "#{@url}/"
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :taint

                f.run
                f.sitemap.should == { "#{@url}/" => 200 }
            end
        end
    end

    describe '#push_to_page_queue' do
        let(:page) { Arachni::Page.from_url( @url + '/train/true' ) }

        it 'pushes it to the page audit queue and returns true' do
            subject.options.audit.elements :links, :forms, :cookies
            subject.checks.load :taint

            subject.page_queue_total_size.should == 0
            subject.push_to_page_queue( page ).should be_true
            subject.run

            subject.report.issues.size.should == 1
            subject.page_queue_total_size.should > 0
        end

        it 'updates the #sitemap with the DOM URL' do
            subject.options.audit.elements :links, :forms, :cookies
            subject.checks.load :taint

            subject.sitemap.should be_empty

            page = Arachni::Page.from_url( @url + '/link' )
            page.dom.url = @url + '/link/#/stuff'

            subject.push_to_page_queue page
            subject.sitemap.should include @url + '/link/#/stuff'
        end

        it "passes it to #{Arachni::ElementFilter}#update_from_page_cache" do
            page = Arachni::Page.from_url( @url + '/link' )

            Arachni::ElementFilter.should receive(:update_from_page_cache).with(page)

            subject.push_to_page_queue page
        end

        context 'when the page has already been seen' do
            it 'ignores it' do
                page = Arachni::Page.from_url( @url + '/stuff' )

                subject.page_queue_total_size.should == 0
                subject.push_to_page_queue( page )
                subject.push_to_page_queue( page )
                subject.push_to_page_queue( page )
                subject.page_queue_total_size.should == 1
            end

            it 'returns false' do
                page = Arachni::Page.from_url( @url + '/stuff' )

                subject.page_queue_total_size.should == 0
                subject.push_to_page_queue( page ).should be_true
                subject.push_to_page_queue( page ).should be_false
                subject.push_to_page_queue( page ).should be_false
                subject.page_queue_total_size.should == 1
            end
        end

        context 'when #accepts_more_pages?' do
            context false do
                it 'returns false' do
                    subject.stub(:accepts_more_pages?) { false }
                    subject.push_to_page_queue( page ).should be_false
                end
            end

            context true do
                it 'returns true' do
                    subject.stub(:accepts_more_pages?) { true }
                    subject.push_to_page_queue( page ).should be_true
                end
            end
        end

        context "when #{Arachni::Page::Scope}#out? is true" do
            it 'returns false' do
                Arachni::Page::Scope.any_instance.stub(:out?) { true }
                subject.push_to_page_queue( page ).should be_false
            end
        end

        context "when #{Arachni::URI::Scope}#redundant? is true" do
            it 'returns false' do
                Arachni::Page::Scope.any_instance.stub(:redundant?) { true }
                subject.push_to_page_queue( page ).should be_false
            end
        end

        context "when #{Arachni::Page::Scope}#auto_redundant? is true" do
            it 'returns false' do
                Arachni::Page::Scope.any_instance.stub(:auto_redundant?) { true }
                subject.push_to_page_queue( page ).should be_false
            end
        end
    end

    describe '#push_to_url_queue' do
        it 'pushes a URL to the URL audit queue' do
            subject.options.audit.elements :links, :forms, :cookies
            subject.checks.load :taint

            subject.url_queue_total_size.should == 0
            subject.push_to_url_queue(  @url + '/link' ).should be_true
            subject.run

            subject.report.issues.size.should == 1
            subject.url_queue_total_size.should == 3
        end

        context 'when the URL has already been seen' do
            it 'returns false' do
                subject.push_to_url_queue( @url + '/link' ).should be_true
                subject.push_to_url_queue( @url + '/link' ).should be_false
            end

            it 'ignores it' do
                subject.url_queue_total_size.should == 0
                subject.push_to_url_queue( @url + '/link' )
                subject.push_to_url_queue( @url + '/link' )
                subject.push_to_url_queue( @url + '/link' )
                subject.url_queue_total_size.should == 1
            end
        end

        context 'when #accepts_more_pages?' do
            context false do
                it 'returns false' do
                    subject.stub(:accepts_more_pages?) { false }
                    subject.push_to_url_queue( @url ).should be_false
                end
            end

            context true do
                it 'returns true' do
                    subject.stub(:accepts_more_pages?) { true }
                    subject.push_to_url_queue( @url ).should be_true
                end
            end
        end

        context "when #{Arachni::URI::Scope}#out? is true" do
            it 'returns false' do
                Arachni::URI::Scope.any_instance.stub(:out?) { true }
                subject.push_to_url_queue( @url ).should be_false
            end
        end

        context "when #{Arachni::URI::Scope}#redundant? is true" do
            it 'returns false' do
                Arachni::URI::Scope.any_instance.stub(:redundant?) { true }
                subject.push_to_url_queue( @url ).should be_false
            end
        end

        context "when #{Arachni::URI::Scope}#auto_redundant? is true" do
            it 'returns false' do
                Arachni::URI::Scope.any_instance.stub(:auto_redundant?) { true }
                subject.push_to_url_queue( @url ).should be_false
            end
        end
    end

end
