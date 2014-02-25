require 'spec_helper'

describe Arachni::Element::Link::DOM do
    it_should_behave_like 'element_dom'

    def auditable_extract_parameters( page )
        { 'param' => page.document.css('#container').text }
    end

    before :each do
        @framework = Arachni::Framework.new
        page       = Arachni::Page.from_url( "#{url}/link" )
        auditor    = Auditor.new( page, @framework )

        @link = page.links.first
        @link.dom.auditor = auditor
    end

    after :each do
        @framework.clean_up
        @framework.reset
    end

    subject { @link.dom }
    let(:parent) { @link }
    let(:url) { web_server_url_for( :link_dom ) }

    let(:inputable) do
        f = Arachni::Page.from_url( "#{url}/link/inputable" ).forms.first
        f.dom.auditor = auditor
        f
    end

    describe '#inputs' do
        it 'parses query-style inputs from URL fragments' do
            subject.inputs.should == { 'param' => 'some-name' }
        end
    end

    describe '#fragment' do
        it 'returns the URL fragment' do
            subject.fragment.should == '/test/?param=some-name'
        end
    end

    describe '#fragment_path' do
        it 'returns the path from the URL fragment' do
            subject.fragment_path.should == '/test/'
        end
    end

    describe '#fragment_query' do
        it 'returns the query from the URL fragment' do
            subject.fragment_query.should == 'param=some-name'
        end
    end

    describe '#locate' do
        it 'locates the live element' do
            called = false
            subject.with_browser do |browser|
                subject.browser = browser
                browser.load subject.page

                element = subject.locate
                element.should be_kind_of Watir::Anchor

                parent.class.from_document(parent.url, Nokogiri::HTML(element.html)).first.should == parent
                called = true
            end

            subject.auditor.browser_cluster.wait
            called.should be_true
        end
    end

    describe '#trigger' do
        it 'triggers the event required to submit the element' do
            inputs = { 'param' => 'The.Dude' }
            subject.update inputs

            called = false
            subject.with_browser do |browser|
                subject.browser = browser

                subject.trigger

                subject.inputs.should == auditable_extract_parameters( browser.to_page )
                called = true
            end

            subject.auditor.browser_cluster.wait
            called.should be_true
        end
    end

end
