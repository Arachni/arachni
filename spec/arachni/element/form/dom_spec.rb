require 'spec_helper'

describe Arachni::Element::Form::DOM do
    it_should_behave_like 'element_dom'

    def auditable_extract_parameters( page )
        YAML.load( page.document.css( 'body' ).text )
    end

    before :each do
        @framework = Arachni::Framework.new
        @page      = Arachni::Page.from_url( "#{url}/form" )
        @auditor   = Auditor.new( @page, @framework )

        @form = @page.forms.first.dom
        @form.auditor = auditor
    end

    after :each do
        @framework.clean_up
        @framework.reset
    end

    subject { @form }
    let(:parent) { @form.parent }
    let(:url) { web_server_url_for( :form_dom ) }
    let(:auditor) { @auditor }
    let(:inputable) do
        f = Arachni::Page.from_url( "#{url}/form/inputable" ).forms.first.dom
        f.auditor = auditor
        f
    end

    describe '#type' do
        it 'returns :form_dom' do
            subject.type.should == :form_dom
        end
    end

    describe '.type' do
        it 'returns :form_dom' do
            described_class.type.should == :form_dom
        end
    end

    describe '#parent' do
        it 'returns the parent element' do
            subject.parent.should be_kind_of Arachni::Element::Form
        end
    end

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
                element.should be_kind_of Watir::Form

                parent.class.from_document(
                    parent.url, Nokogiri::HTML(element.html)
                ).first.should == parent

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

        it 'returns a playable transition' do
            inputs = { 'param'  => 'The.Dude' }
            subject.update inputs

            transition = nil
            called = false
            subject.with_browser do |browser|
                subject.browser = browser
                browser.load subject.page

                transition = subject.trigger

                page = browser.to_page

                subject.inputs.should == auditable_extract_parameters( page )
                called = true
            end

            subject.auditor.browser_cluster.wait
            called.should be_true

            called = false
            auditor.with_browser do |browser|
                browser.load subject.page
                auditable_extract_parameters( browser.to_page ).should be_false

                transition.play browser
                auditable_extract_parameters( browser.to_page ).should == inputs
                called = true
            end
            auditor.browser_cluster.wait
            called.should be_true
        end
    end

end
