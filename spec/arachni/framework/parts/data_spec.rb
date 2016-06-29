require 'spec_helper'

describe Arachni::Framework::Parts::Data do
    include_examples 'framework'

    describe '#data' do
        it "returns #{Arachni::Data::Framework}" do
            expect(subject.data).to be_kind_of Arachni::Data::Framework
        end
    end

    describe '#sitemap' do
        it 'returns a hash with covered URLs and HTTP status codes' do
            Arachni::Framework.new do |f|
                f.options.url = "#{@url}/"
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :signature

                f.run
                expect(f.sitemap).to eq({ "#{@url}/" => 200 })
            end
        end
    end

    describe '#push_to_page_queue' do
        let(:page) { Arachni::Page.from_url( @url + '/train/true' ) }

        it 'pushes it to the page audit queue and returns true' do
            expect(subject.page_queue_total_size).to eq(0)
            expect(subject.push_to_page_queue( page )).to be_truthy
            expect(subject.page_queue_total_size).to be > 0
        end

        it 'updates the #sitemap with the DOM URL' do
            subject.options.audit.elements :links, :forms, :cookies
            subject.checks.load :signature

            expect(subject.sitemap).to be_empty

            page = Arachni::Page.from_url( @url + '/link' )
            page.dom.url = @url + '/link/#/stuff'

            subject.push_to_page_queue page
            expect(subject.sitemap).to include @url + '/link/#/stuff'
        end

        it "passes it to #{Arachni::ElementFilter}#update_from_page_cache" do
            page = Arachni::Page.from_url( @url + '/link' )

            expect(Arachni::ElementFilter).to receive(:update_from_page_cache).with(page)

            subject.push_to_page_queue page
        end

        context 'when the page has already been seen' do
            it 'ignores it' do
                page = Arachni::Page.from_url( @url + '/stuff' )

                expect(subject.page_queue_total_size).to eq(0)
                subject.push_to_page_queue( page )
                subject.push_to_page_queue( page )
                subject.push_to_page_queue( page )
                expect(subject.page_queue_total_size).to eq(1)
            end

            it 'returns false' do
                page = Arachni::Page.from_url( @url + '/stuff' )

                expect(subject.page_queue_total_size).to eq(0)
                expect(subject.push_to_page_queue( page )).to be_truthy
                expect(subject.push_to_page_queue( page )).to be_falsey
                expect(subject.push_to_page_queue( page )).to be_falsey
                expect(subject.page_queue_total_size).to eq(1)
            end
        end

        context 'when #accepts_more_pages?' do
            context 'false' do
                it 'returns false' do
                    allow(subject).to receive(:accepts_more_pages?) { false }
                    expect(subject.push_to_page_queue( page )).to be_falsey
                end
            end

            context 'true' do
                it 'returns true' do
                    allow(subject).to receive(:accepts_more_pages?) { true }
                    expect(subject.push_to_page_queue( page )).to be_truthy
                end
            end
        end

        context "when #{Arachni::Page::Scope}#out? is true" do
            it 'returns false' do
                allow_any_instance_of(Arachni::Page::Scope).to receive(:out?) { true }
                expect(subject.push_to_page_queue( page )).to be_falsey
            end
        end

        context "when #{Arachni::URI::Scope}#redundant? is true" do
            it 'returns false' do
                allow_any_instance_of(Arachni::Page::Scope).to receive(:redundant?) { true }
                expect(subject.push_to_page_queue( page )).to be_falsey
            end
        end

        context "when #{Arachni::Page::Scope}#auto_redundant? is true" do
            it 'returns false' do
                allow_any_instance_of(Arachni::Page::Scope).to receive(:auto_redundant?) { true }
                expect(subject.push_to_page_queue( page )).to be_falsey
            end
        end
    end

    describe '#push_to_url_queue' do
        it 'pushes a URL to the URL audit queue' do
            subject.options.audit.elements :links, :forms, :cookies
            subject.checks.load :signature

            expect(subject.url_queue_total_size).to eq(0)
            expect(subject.push_to_url_queue(  @url + '/link' )).to be_truthy
            subject.run

            expect(subject.report.issues.size).to eq(1)
            expect(subject.url_queue_total_size).to eq(3)
        end

        context 'when the URL has already been seen' do
            it 'returns false' do
                expect(subject.push_to_url_queue( @url + '/link' )).to be_truthy
                expect(subject.push_to_url_queue( @url + '/link' )).to be_falsey
            end

            it 'ignores it' do
                expect(subject.url_queue_total_size).to eq(0)
                subject.push_to_url_queue( @url + '/link' )
                subject.push_to_url_queue( @url + '/link' )
                subject.push_to_url_queue( @url + '/link' )
                expect(subject.url_queue_total_size).to eq(1)
            end
        end

        context 'when #accepts_more_pages?' do
            context 'false' do
                it 'returns false' do
                    allow(subject).to receive(:accepts_more_pages?) { false }
                    expect(subject.push_to_url_queue( @url )).to be_falsey
                end
            end

            context 'true' do
                it 'returns true' do
                    allow(subject).to receive(:accepts_more_pages?) { true }
                    expect(subject.push_to_url_queue( @url )).to be_truthy
                end
            end
        end

        context "when #{Arachni::URI::Scope}#out? is true" do
            it 'returns false' do
                allow_any_instance_of(Arachni::URI::Scope).to receive(:out?) { true }
                expect(subject.push_to_url_queue( @url )).to be_falsey
            end
        end

        context "when #{Arachni::URI::Scope}#redundant? is true" do
            it 'returns false' do
                allow_any_instance_of(Arachni::URI::Scope).to receive(:redundant?) { true }
                expect(subject.push_to_url_queue( @url )).to be_falsey
            end
        end

        context "when #{Arachni::URI::Scope}#auto_redundant? is true" do
            it 'returns false' do
                allow_any_instance_of(Arachni::URI::Scope).to receive(:auto_redundant?) { true }
                expect(subject.push_to_url_queue( @url )).to be_falsey
            end
        end
    end

end
