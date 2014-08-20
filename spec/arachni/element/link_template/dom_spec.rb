require 'spec_helper'

describe Arachni::Element::LinkTemplate::DOM do
    it_should_behave_like 'element_dom'

    def auditable_extract_parameters( page )
        { 'param' => page.document.css('#container').text }
    end

    before :each do
        @framework = Arachni::Framework.new
        @page      = Arachni::Page.from_url( url )
        @auditor   = Auditor.new( @page, @framework )

        Arachni::Options.audit.link_template_doms = [
            /param\/(?<param>.+)/,
            /input1\/(?<input1>.+)\/input2\/(?<input2>.+)/
        ]

        @link = @page.link_templates.first.dom
        @link.auditor = @auditor
    end

    after :each do
        @framework.clean_up
        @framework.reset
    end

    subject { @link }
    let(:parent) { @link.parent }
    let(:url) { web_server_url_for( :link_template_dom ) }
    let(:auditor) { @auditor }
    let(:inputtable) do
        l = Arachni::Page.from_url( "#{url}/inputtable" ).
            link_templates.first.dom
        l.auditor = auditor
        l
    end

    let(:mutable) do
        inputtable.dup
    end

    describe '#type' do
        it 'returns :link_dom' do
            subject.type.should == :link_template_dom
        end
    end

    describe '.type' do
        it 'returns :link_dom' do
            described_class.type.should == :link_template_dom
        end
    end

    describe '#extract_inputs' do
        it "delegates to #{Arachni::Element::LinkTemplate}.extract_inputs" do
            Arachni::Element::LinkTemplate.stub(:extract_inputs) { |arg| "#{arg}1" }
            subject.extract_inputs( 'blah' ).should == 'blah1'
        end
    end

    %w(encode decode).each do |m|
        describe "##{m}" do
            it 'returns the string as is' do
                subject.send( m, 'blah' ).should == 'blah'
            end
        end
    end

    describe '#parent' do
        it 'returns the parent element' do
            subject.parent.should be_kind_of Arachni::Element::LinkTemplate
        end
    end

    describe '#inputs' do
        it 'parses query-style inputs from URL fragments' do
            subject.inputs.should == { 'param' => 'some-name' }
        end
    end

    describe '#fragment' do
        it 'returns the URL fragment' do
            subject.fragment.should == '/param/some-name'
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
                auditable_extract_parameters( browser.to_page ).should ==
                    { 'param' => '' }

                transition.play browser
                auditable_extract_parameters( browser.to_page ).should == inputs
                called = true
            end
            auditor.browser_cluster.wait
            called.should be_true
        end
    end

    describe '.to_rpc_data' do
        it 'converts the #template to a string' do
            subject.to_rpc_data['template'].should == subject.template.source
        end
    end

    describe '.data_from_node' do
        let(:node) { subject.node }
        let(:data) { described_class.data_from_node( node ) }

        it 'returns a hash with DOM data' do
            data.should == {
                inputs:   {
                    'param' => 'some-name'
                },
                template: /param\/(?<param>.+)/,
                fragment: '/param/some-name'
            }
        end

        it 'decodes the fragment before extracting inputs' do
            html = "<a href='#/param/bl%20ah'>Stuff</a>"
            node = Nokogiri::HTML.fragment(html).children.first

            described_class.data_from_node( node )[:inputs].should == {
                'param' => 'bl ah'
            }
        end

        context 'when there is no URL fragment' do
            let(:node) do
                Nokogiri::HTML.fragment( "<a href='/stuff/here'>Stuff</a>" ).
                    children.first
            end

            it 'return nil' do
                described_class.data_from_node( node ).should be_nil
            end
        end

        context 'when there are no inputs' do
            let(:node) do
                Nokogiri::HTML.fragment( "<a href='#/param2/val'>Stuff</a>" ).
                    children.first
            end

            it 'return nil' do
                described_class.data_from_node( node ).should be_nil
            end
        end
    end

end
