require 'spec_helper'

describe Arachni::Element::Cookie::DOM do
    inputs = { 'param' => '1' }

    it_should_behave_like 'element_dom'

    it_should_behave_like 'submittable_dom'
    it_should_behave_like 'inputtable_dom', single_input: true, inputs: inputs
    it_should_behave_like 'mutable_dom',    single_input: true, inputs: inputs
    it_should_behave_like 'auditable_dom'

    def auditable_extract_parameters( page )
        Hash[[Nokogiri::HTML(page.body).css('#container').text.split( '=' )]]
    end

    def run
        auditor.browser_cluster.wait
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

    let(:auditor) { @auditor }

    subject { parent.dom }

    let(:url) { web_server_url_for( :cookie_dom ) }

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
            expect(subject.name).to eq(parent.name)
        end
    end

    describe '#value' do
        it 'returns the cookie value' do
            expect(subject.value).to eq(parent.value)
        end
    end

    describe '#to_set_cookie' do
        it 'returns a string in a Set-Cookie response header format' do
            expect(subject.to_set_cookie).to eq(parent.to_set_cookie)
        end
    end

    describe '#type' do
        it 'returns :cookie_dom' do
            expect(subject.type).to eq(:cookie_dom)
        end
    end

    describe '.type' do
        it 'returns :cookie_dom' do
            expect(described_class.type).to eq(:cookie_dom)
        end
    end

    describe '#parent' do
        it 'returns the parent element' do
            expect(subject.parent).to be_kind_of Arachni::Element::Cookie
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

                expect(subject.inputs).to eq(auditable_extract_parameters( browser.to_page ))
                called = true
            end

            subject.auditor.browser_cluster.wait
            expect(called).to be_truthy
        end

        it 'returns a playable transition' do
            inputs = { 'param'  => 'The.Dude' }
            subject.update inputs

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

                transitions.each do |transition|
                    transition.play browser
                end

                expect(auditable_extract_parameters( browser.to_page )).to eq(inputs)
                called = true
            end
            auditor.browser_cluster.wait
            expect(called).to be_truthy
        end
    end

end
