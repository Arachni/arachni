require 'spec_helper'

describe Arachni::Element::UIForm do
    html = '<button id="insert">Insert into DOM</button'

    it_should_behave_like 'with_auditor'
    it_should_behave_like 'dom_only', html

    def new_element( source )
        described_class.new(
            method:       'click',
            action:       page.url,
            source:       source,
            inputs:       { 'my-input' => 'stuff' },
            opening_tags: {
                'my-input' => "<input id=\"my-input\" type=\"text\" value=\"stuff\">"
            }
        )
    end

    subject do
        new_element( html )
    end
    let(:inputtable) do
        new_element( html )
    end
    let(:url) { "#{web_server_url_for( :ui_form_dom )}/" }

    let(:browser) { @browser }
    let(:page) { Arachni::Page.from_url( url ) }

    describe '.new' do
        describe ':opening_tags' do
            it 'sets the #opening_tags' do
                expect(subject.opening_tags).to eq(
                    'my-input' => "<input id=\"my-input\" type=\"text\" value=\"stuff\">"
                )
            end

            context 'when nil' do
                subject do
                    described_class.new(
                        method: 'click',
                        action: page.url
                    )
                end

                it 'sets the empty array' do
                    expect(subject.opening_tags).to eq([])
                end
            end
        end
    end

    describe '#dup' do
        it 'duplicated #opening_tags' do
            dupped = subject.dup
            expect(dupped.opening_tags).to eq subject.opening_tags
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

        context 'when there no buttons' do
            let(:url) { "#{super()}/without-button" }

            it 'returns empty array' do
                expect(described_class.from_browser( @browser, page )).to be_empty
            end
        end

        context 'when there are buttons' do
            context 'as <button>' do
                let(:url) { "#{super()}/button" }
                let(:source) { '<button id="insert">' }

                context 'without inputs' do
                    let(:url) { "#{super()}/without-inputs" }

                    it 'returns empty array' do
                        expect(described_class.from_browser( @browser, page )).to be_empty
                    end
                end

                context 'with inputs as' do
                    context '<input type="text">' do
                        let(:url) { "#{super()}/input/type/text" }

                        context 'and buttons with events' do
                            let(:url) { "#{super()}/with_events" }

                            it 'returns array of elements' do
                                form = described_class.from_browser( @browser, page ).first

                                expect(form.source).to eq source
                                expect(form.url).to eq page.url
                                expect(form.action).to eq page.url
                                expect(form.method).to eq :click
                                expect(form.inputs).to eq( 'my-input' => 'stuff' )
                            end
                        end

                        context 'and buttons without events' do
                            let(:url) { "#{super()}/without_events" }

                            it 'returns empty array' do
                                expect(described_class.from_browser( @browser, page )).to be_empty
                            end
                        end
                    end

                    context '<input>' do
                        let(:url) { "#{super()}/input/type/none" }

                        context 'and buttons with events' do
                            let(:url) { "#{super()}/with_events" }

                            it 'returns array of elements' do
                                form = described_class.from_browser( @browser, page ).first

                                expect(form.source).to eq source
                                expect(form.url).to eq page.url
                                expect(form.action).to eq page.url
                                expect(form.method).to eq :click
                                expect(form.inputs).to eq( 'my-input' => 'stuff' )
                            end
                        end

                        context 'and buttons without events' do
                            let(:url) { "#{super()}/without_events" }

                            it 'returns empty array' do
                                expect(described_class.from_browser( @browser, page )).to be_empty
                            end
                        end
                    end

                    context '<textarea>' do
                        let(:url) { "#{super()}/textarea" }

                        context 'and buttons with events' do
                            let(:url) { "#{super()}/with_events" }

                            it 'returns array of elements' do
                                form = described_class.from_browser( @browser, page ).first

                                expect(form.source).to eq source
                                expect(form.url).to eq page.url
                                expect(form.action).to eq page.url
                                expect(form.method).to eq :click
                                expect(form.inputs).to eq( 'my-input' => 'stuff' )
                            end
                        end

                        context 'and buttons without events' do
                            let(:url) { "#{super()}/without_events" }

                            it 'returns empty array' do
                                expect(described_class.from_browser( @browser, page )).to be_empty
                            end
                        end
                    end
                end
            end

            context 'as <input type="button">' do
                let(:url) { "#{super()}/input-button" }
                let(:source) { '<input type="button" id="insert" value="Insert into DOM">' }

                context 'without inputs' do
                    let(:url) { "#{super()}/without-inputs" }

                    it 'returns empty array' do
                        expect(described_class.from_browser( @browser, page )).to be_empty
                    end
                end

                context 'with inputs as' do
                    context '<input>' do
                        let(:url) { "#{super()}/input" }

                        context 'and buttons with events' do
                            let(:url) { "#{super()}/with_events" }

                            it 'returns array of elements' do
                                form = described_class.from_browser( @browser, page ).first

                                expect(form.source).to eq source
                                expect(form.url).to eq page.url
                                expect(form.action).to eq page.url
                                expect(form.method).to eq :click
                                expect(form.inputs).to eq( 'my-input' => 'stuff' )
                            end
                        end

                        context 'and buttons without events' do
                            let(:url) { "#{super()}/without_events" }

                            it 'returns array of elements' do
                                expect(described_class.from_browser( @browser, page )).to be_empty
                            end
                        end
                    end

                    context '<textarea>' do
                        let(:url) { "#{super()}/textarea" }

                        context 'and buttons with events' do
                            let(:url) { "#{super()}/with_events" }

                            it 'returns array of elements' do
                                form = described_class.from_browser( @browser, page ).first

                                expect(form.source).to eq source
                                expect(form.url).to eq page.url
                                expect(form.action).to eq page.url
                                expect(form.method).to eq :click
                                expect(form.inputs).to eq( 'my-input' => 'stuff' )
                            end
                        end

                        context 'and buttons without events' do
                            let(:url) { "#{super()}/without_events" }

                            it 'returns array of elements' do
                                expect(described_class.from_browser( @browser, page )).to be_empty
                            end
                        end
                    end
                end
            end

            context 'as <input type="submit">' do
                let(:url) { "#{super()}/input-submit" }
                let(:source) { '<input type="submit" id="insert" value="Insert into DOM">' }

                context 'without inputs' do
                    let(:url) { "#{super()}/without-inputs" }

                    it 'returns empty array' do
                        expect(described_class.from_browser( @browser, page )).to be_empty
                    end
                end

                context 'with inputs as' do
                    context '<input>' do
                        let(:url) { "#{super()}/input" }

                        context 'and buttons with events' do
                            let(:url) { "#{super()}/with_events" }

                            it 'returns array of elements' do
                                form = described_class.from_browser( @browser, page ).first

                                expect(form.source).to eq source
                                expect(form.url).to eq page.url
                                expect(form.action).to eq page.url
                                expect(form.method).to eq :click
                                expect(form.inputs).to eq( 'my-input' => 'stuff' )
                            end
                        end

                        context 'and buttons without events' do
                            let(:url) { "#{super()}/without_events" }

                            it 'returns array of elements' do
                                expect(described_class.from_browser( @browser, page )).to be_empty
                            end
                        end
                    end

                    context '<textarea>' do
                        let(:url) { "#{super()}/textarea" }

                        context 'and buttons with events' do
                            let(:url) { "#{super()}/with_events" }

                            it 'returns array of elements' do
                                form = described_class.from_browser( @browser, page ).first

                                expect(form.source).to eq source
                                expect(form.url).to eq page.url
                                expect(form.action).to eq page.url
                                expect(form.method).to eq :click
                                expect(form.inputs).to eq( 'my-input' => 'stuff' )
                            end
                        end

                        context 'and buttons without events' do
                            let(:url) { "#{super()}/without_events" }

                            it 'returns array of elements' do
                                expect(described_class.from_browser( @browser, page )).to be_empty
                            end
                        end
                    end
                end
            end
        end
    end

end
