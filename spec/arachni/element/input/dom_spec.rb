require 'spec_helper'

describe Arachni::Element::Input::DOM do
    inputs = { 'my-input' => '1' }

    it_should_behave_like 'element_dom'

    it_should_behave_like 'with_node'

    it_should_behave_like 'submittable_dom'
    it_should_behave_like 'inputtable_dom', single_input: true, inputs: inputs
    it_should_behave_like 'mutable_dom',    single_input: true, inputs: inputs
    it_should_behave_like 'auditable_dom'

    def run
        auditor.browser_cluster.wait
    end

    def auditable_extract_parameters( page )
        { 'my-input' => page.document.css('#container').text.strip }
    end

    def element
        e = Arachni::Element::Input.new(
            method: 'input',
            action: @page.url,
            source: '<input oninput="handleOnInput();" id="my-input" name="my-input" value="1" />'
        ).dom
        e.page    = @page
        e.auditor = @auditor
        e
    end

    before :each do
        @framework = Arachni::Framework.new
        @page      = Arachni::Page.from_url( url )
        @auditor   = Auditor.new( @page, @framework )
    end

    after :each do
        @framework.clean_up
        @framework.reset
    end

    subject { element }
    let(:parent) { subject.parent }
    let(:url) { web_server_url_for( :input_dom ) }
    let(:auditor) { @auditor }
    let(:inputtable) { element }

    describe '#type' do
        it 'returns :input_dom' do
            expect(subject.type).to eq(:input_dom)
        end
    end

    describe '.type' do
        it 'returns :input_dom' do
            expect(described_class.type).to eq(:input_dom)
        end
    end

    describe '#parent' do
        it 'returns the parent element' do
            expect(subject.parent).to be_kind_of Arachni::Element::Input
        end
    end

    describe '#inputs' do
        it 'uses the node attribute data' do
            expect(subject.inputs).to eq(inputs)
        end
    end

    describe '#locate' do
        it 'locates the live element' do
            called = false
            subject.with_browser do |browser|
                subject.browser = browser
                browser.load subject.page

                element = subject.locate
                expect(element).to be_kind_of Watir::HTMLElement

                expect(Arachni::Browser::ElementLocator.
                           from_html( element.opening_tag ).attributes
                ).to eq(subject.locator.attributes)

                called = true
            end

            subject.auditor.browser_cluster.wait
            expect(called).to be_truthy
        end
    end

    describe '#trigger' do
        let(:new_inputs) { { subject.inputs.keys.first  => 'The.Dude' } }

        it 'triggers the event required to submit the element' do
            subject.update new_inputs

            called = false
            subject.with_browser do |browser|
                subject.browser = browser
                browser.load subject.page

                subject.trigger

                page = browser.to_page

                expect(subject.inputs).to eq(auditable_extract_parameters( page ))
                called = true
            end

            subject.auditor.browser_cluster.wait
            expect(called).to be_truthy
        end

        it 'returns a playable transition' do
            subject.update new_inputs

            transitions = []
            called = false
            subject.with_browser do |browser|
                subject.browser = browser
                browser.load subject.page

                transitions = subject.trigger

                page = browser.to_page

                expect(subject.inputs).to eq(auditable_extract_parameters( page ))
                called = true
            end

            subject.auditor.browser_cluster.wait
            expect(called).to be_truthy

            called = false
            auditor.with_browser do |browser|
                browser.load subject.page
                expect(auditable_extract_parameters( browser.to_page ).values.first).to eq ''

                transitions.each do |transition|
                    transition.play browser
                end

                expect(auditable_extract_parameters( browser.to_page )).to eq(new_inputs)
                called = true
            end
            auditor.browser_cluster.wait
            expect(called).to be_truthy
        end
    end

end
