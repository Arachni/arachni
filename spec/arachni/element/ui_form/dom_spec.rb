require 'spec_helper'

describe Arachni::Element::UIForm::DOM do
    inputs = { 'my-input' => 'stuff' }

    it_should_behave_like 'element_dom'

    it_should_behave_like 'with_node'
    it_should_behave_like 'with_auditor'

    it_should_behave_like 'locatable_dom'
    it_should_behave_like 'submittable_dom'
    it_should_behave_like 'inputtable_dom', inputs: inputs
    it_should_behave_like 'mutable_dom',    inputs: inputs
    it_should_behave_like 'auditable_dom'

    def run
        auditor.browser_cluster.wait
    end

    def auditable_extract_parameters( page )
        {
            'my-input' => Nokogiri::HTML(page.body).css('#container').text.strip
        }
    end

    def element( inputs )
        e = Arachni::Element::UIForm.new(
            method:       'click',
            action:       @page.url,
            source:       '<button id="insert">Insert into DOM</button>',
            inputs:       inputs,
            opening_tags: {
                'my-input' => "<input id=\"my-input\" type=\"text\" value=\"stuff\">"
            }
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

    subject { element( inputs ) }
    let(:parent) { subject.parent }
    let(:url) { web_server_url_for( :ui_form_dom ) }
    let(:auditor) { @auditor }
    let(:inputtable) { element( inputs ) }

    describe '#type' do
        it 'returns :ui_form_dom' do
            expect(subject.type).to eq(:ui_form_dom)
        end
    end

    describe '.type' do
        it 'returns :ui_form_dom' do
            expect(described_class.type).to eq(:ui_form_dom)
        end
    end

    describe '#parent' do
        it 'returns the parent element' do
            expect(subject.parent).to be_kind_of Arachni::Element::UIForm
        end
    end

    describe '#inputs' do
        it 'returns the parent inputs' do
            expect(subject.inputs).to eq subject.parent.inputs
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

    describe '#coverage_id' do
        let(:action) { @page.url }
        let(:method) { 'click' }
        let(:source) { '<button id="insert">Insert into DOM</button>' }
        let(:opening_tags) { {
            'my-input' => "<input id=\"my-input\" type=\"text\" value=\"stuff\">"
        } }
        let(:options) do
            {
                method:       method,
                action:       action,
                source:       source,
                inputs:       inputs,
                opening_tags: opening_tags
            }
        end

        def get_element( o = {} )
            Arachni::Element::UIForm.new( options.merge( o ) ).dom
        end

        it 'takes the #method into consideration' do
            s1 = get_element
            s2 = get_element( method: 'mouseover' )

            expect(s1.coverage_id).to_not eq s2.coverage_id
        end

        it 'takes the #locator into consideration' do
            s1 = get_element
            s2 = get_element( source: '<button id="insert2">Insert into DOM</button>' )

            expect(s1.coverage_id).to_not eq s2.coverage_id
        end
    end

    describe '#id' do
        let(:action) { @page.url }
        let(:method) { 'click' }
        let(:source) { '<button id="insert">Insert into DOM</button>' }
        let(:opening_tags) { {
            'my-input' => "<input id=\"my-input\" type=\"text\" value=\"stuff\">"
        } }
        let(:options) do
            {
                method:       method,
                action:       action,
                source:       source,
                inputs:       inputs,
                opening_tags: opening_tags
            }
        end

        def get_element( o = {} )
            Arachni::Element::UIForm.new( options.merge( o ) ).dom
        end

        it 'takes the #method into consideration' do
            s1 = get_element
            s2 = get_element( method: 'mouseover' )

            expect(s1.id).to_not eq s2.id
        end

        it 'takes the #locator into consideration' do
            s1 = get_element
            s2 = get_element( source: '<button id="insert2">Insert into DOM</button>' )

            expect(s1.id).to_not eq s2.id
        end
    end
end
