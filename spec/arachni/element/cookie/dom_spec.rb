require 'spec_helper'

describe Arachni::Element::Cookie::DOM do
    it_should_behave_like 'element_dom', single_input: true, without_node: true

    def auditable_extract_parameters( page )
        Hash[[page.document.css('#container').text.split( '=' )]]
    end

    before :each do
        @framework = Arachni::Framework.new
        @page      = Arachni::Page.from_url( "#{url}/" )
        @auditor   = Auditor.new( @page, @framework )
    end

    after :each do
        @framework.clean_up
        @framework.reset
    end

    subject { parent.dom }
    let(:parent) do
        Arachni::Element::Cookie.new(
            action: "#{url}/",
            inputs: {
                'param' => 'some-name'
            }
        ).tap do |c|
            c.page = @page
            c.dom.auditor = auditor
        end
    end
    let(:url) { web_server_url_for( :cookie_dom ) }
    let(:auditor) { @auditor }
    let(:inputtable) do
        Arachni::Element::Cookie.new(
            action: "#{url}/",
            inputs: {
                'input1' => 'some-name'
            }
        ).tap do |c|
            c.page = @page
            c.dom.auditor = auditor
        end.dom
    end

    describe '#name' do
        it 'returns the cookie name' do
            subject.name.should == parent.name
        end
    end

    describe '#value' do
        it 'returns the cookie value' do
            subject.value.should == parent.value
        end
    end

    describe '#to_set_cookie' do
        it 'returns a string in a Set-Cookie response header format' do
            subject.to_set_cookie.should == parent.to_set_cookie
        end
    end

    %w(encode decode).each do |m|
        describe "##{m}" do
            it "delegates to #{Arachni::Element::Cookie}.#{m}" do
                Arachni::Element::Cookie.stub(m) { |arg| "#{arg}1" }
                subject.send( m, 'blah' ).should == 'blah1'
            end
        end
    end

    describe '#type' do
        it 'returns :cookie_dom' do
            subject.type.should == :cookie_dom
        end
    end

    describe '.type' do
        it 'returns :cookie_dom' do
            described_class.type.should == :cookie_dom
        end
    end

    describe '#parent' do
        it 'returns the parent element' do
            subject.parent.should be_kind_of Arachni::Element::Cookie
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

                transition.play browser
                auditable_extract_parameters( browser.to_page ).should == inputs
                called = true
            end
            auditor.browser_cluster.wait
            called.should be_true
        end
    end

end
