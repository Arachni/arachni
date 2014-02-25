require 'spec_helper'

describe Arachni::Element::Form::DOM do
    it_should_behave_like 'element_dom'

    def auditable_extract_parameters( page )
        YAML.load( page.document.css( 'body' ).text )
    end

    before :each do
        @framework = Arachni::Framework.new
        page       = Arachni::Page.from_url( "#{url}/form" )
        auditor    = Auditor.new( page, @framework )

        @form = page.forms.first
        @form.dom.auditor = auditor
    end

    after :each do
        @framework.clean_up
        @framework.reset
    end

    subject { @form.dom }
    let(:parent) { @form }
    let(:url) { web_server_url_for( :form_dom ) }

    describe '#inputs' do
        it 'uses the parent\'s inputs' do
            subject.inputs.should == parent.inputs
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
            inputs = { 'param'  => 'The.Dude' }
            subject.update inputs

            called = false
            subject.with_browser do |browser|
                subject.browser = browser
                browser.load subject.page

                subject.trigger

                page = browser.to_page

                subject.inputs.should == auditable_extract_parameters( page )
                called = true
            end

            subject.auditor.browser_cluster.wait
            called.should be_true
        end
    end

end
