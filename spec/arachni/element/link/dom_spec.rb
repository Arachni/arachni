require 'spec_helper'

describe Arachni::Element::Link::DOM do
    it_should_behave_like 'element_dom'

    before :each do
        @framework = Arachni::Framework.new
        page       = Arachni::Page.from_url( url )
        auditor    = Auditor.new( page, @framework )

        @link = page.links.first
        @link.auditor = auditor
    end

    after :each do
        @framework.clean_up
        @framework.reset
    end

    subject { @link.dom }
    let(:parent) { @link }
    let(:url) { web_server_url_for( :link_dom ) }

    describe '#inputs' do
        it 'parses query-style inputs from URL fragments' do
            subject.inputs.should == {
                'name'  => 'some-name',
                'email' => 'some@email.com'
            }
        end
    end

    describe '#fragment' do
        it 'returns the URL fragment' do
            subject.fragment.should == '/test/?name=some-name&email=some@email.com'
        end
    end

    describe '#fragment_path' do
        it 'returns the path from the URL fragment' do
            subject.fragment_path.should == '/test/'
        end
    end

    describe '#fragment_query' do
        it 'returns the query from the URL fragment' do
            subject.fragment_query.should == 'name=some-name&email=some@email.com'
        end
    end

    describe '#locate' do
        it 'locates the live element' do
            called = false
            subject.with_browser do |browser|
                subject.browser = browser
                browser.load subject.page

                element = subject.locate
                element.should be_kind_of Watir::HTMLElement

                parent.class.from_document(parent.url, Nokogiri::HTML(element.html)).first.should == parent
                called = true
            end

            subject.auditor.browser_cluster.wait
            called.should be_true
        end
    end

    describe '#trigger' do
        it 'triggers the event required to submit the element' do
            inputs = {
                'name'  => 'The Dude',
                'email' => 'the.dude@abides.com'
            }
            subject.update inputs

            called = false
            subject.with_browser do |browser|
                subject.browser = browser

                subject.trigger

                page = browser.to_page

                subject.inputs.should == {
                    'name'  => page.document.css('#container-name').text,
                    'email' => page.document.css('#container-email').text
                }
                called = true
            end

            subject.auditor.browser_cluster.wait
            called.should be_true
        end
    end

end
