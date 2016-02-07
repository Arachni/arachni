require 'spec_helper'

describe Arachni::Element::UIInput do
    html = '<input type=password name="my_first_input" value="my_first_value"" />'

    it_should_behave_like 'with_auditor'
    it_should_behave_like 'dom_only', html

    def new_element( html )
        described_class.new(
            action: url,
            source: html,
            method: 'onmouseover'
        )
    end

    subject { new_element( html ) }
    let(:inputtable) { new_element( html ) }
    let(:url) { "#{web_server_url_for( :input_dom )}/" }

    let(:browser) { @browser }
    let(:page) { Arachni::Page.from_url( url ) }

    describe '#type' do
        it 'returns :ui_input' do
            expect(subject.type).to eq(:ui_input)
        end
    end

    describe '.type' do
        it 'returns :ui_input' do
            expect(described_class.type).to eq(:ui_input)
        end
    end

    describe '.from_browser' do
        before :each do
            @browser = Arachni::Browser.new
            @browser.load page
        end

        after :each do
            @browser.shutdown
        end

        context 'when there no inputs' do
            let(:url) { "#{super()}/without-inputs" }

            it 'returns empty array' do
                expect(described_class.from_browser( @browser, page )).to be_empty
            end
        end

        context 'with inputs as' do
            context '<input type="text">' do
                let(:url) { "#{super()}/input/type/text" }

                context 'with events' do
                    let(:url) { "#{super()}/with_events" }
                    let(:source) { '<input type="text" id="my-input" value="stuff">' }

                    it 'returns array of elements' do
                        input = described_class.from_browser( @browser, page ).first

                        expect(input.source).to eq source
                        expect(input.url).to eq page.url
                        expect(input.action).to eq page.url
                        expect(input.method).to eq :input
                        expect(input.inputs).to eq( 'my-input' => 'stuff' )
                    end
                end

                context 'without events' do
                    let(:url) { "#{super()}/without_events" }

                    it 'returns empty array' do
                        expect(described_class.from_browser( @browser, page )).to be_empty
                    end
                end
            end

            context '<input>' do
                let(:url) { "#{super()}/input/type/none" }

                context 'with events' do
                    let(:url) { "#{super()}/with_events" }
                    let(:source) { '<input id="my-input" value="stuff">' }

                    it 'returns array of elements' do
                        input = described_class.from_browser( @browser, page ).first

                        expect(input.source).to eq source
                        expect(input.url).to eq page.url
                        expect(input.action).to eq page.url
                        expect(input.method).to eq :input
                        expect(input.inputs).to eq( 'my-input' => 'stuff' )
                    end
                end

                context 'without events' do
                    let(:url) { "#{super()}/without_events" }

                    it 'returns empty array' do
                        expect(described_class.from_browser( @browser, page )).to be_empty
                    end
                end
            end

            context '<textarea>' do
                let(:url) { "#{super()}/textarea" }

                context 'with events' do
                    let(:url) { "#{super()}/with_events" }
                    let(:source) { '<textarea id="my-input" type="text">' }

                    it 'returns array of elements' do
                        input = described_class.from_browser( @browser, page ).first

                        expect(input.source).to eq source
                        expect(input.url).to eq page.url
                        expect(input.action).to eq page.url
                        expect(input.method).to eq :input
                        expect(input.inputs).to eq( 'my-input' => '' )
                    end
                end

                context 'without events' do
                    let(:url) { "#{super()}/without_events" }

                    it 'returns empty array' do
                        expect(described_class.from_browser( @browser, page )).to be_empty
                    end
                end
            end
        end
    end
end
