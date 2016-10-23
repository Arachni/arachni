require 'spec_helper'

describe Arachni::Parser::SAX do
    let(:options) do
        {
            stop_on_first: []
        }
    end
    let(:document) { Arachni::Parser.parse( html, options ) }
    let(:html) do
        <<-EOHTML
        <html>
            <div id="my-id">
                <!-- My comment -->
                <p class="my-class">
                    <a href="/stuff">Stuff</a>
                </p>

                My text
            </div>
        </html>
        EOHTML
    end

    it 'parses nodes' do
        children = document.children

        expect(children.size).to eq 1

        html = children.first
        expect(html).to be_kind_of Arachni::Parser::Nodes::Element
        expect(html.name).to eq :html
        expect(html.attributes).to be_empty

        div = html.children.first
        expect(div).to be_kind_of Arachni::Parser::Nodes::Element
        expect(div.name).to eq :div
        expect(div.attributes).to eq({ 'id' => 'my-id' })

        comment = div.children[0]
        expect(comment).to be_kind_of Arachni::Parser::Nodes::Comment
        expect(comment.value).to eq 'My comment'

        p = div.children[1]
        expect(p).to be_kind_of Arachni::Parser::Nodes::Element
        expect(p.name).to eq :p
        expect(p.attributes).to eq({ 'class' => 'my-class' })

        text = div.children[2]
        expect(text).to be_kind_of Arachni::Parser::Nodes::Text
        expect(text.value).to eq 'My text'
    end

    describe '#initialize' do
        describe ':stop_on_first' do
            let(:options) { super().merge( stop_on_first: [ 'div' ] ) }
            let(:html) do
                <<-EOHTML
                <html>
                    <div>
                        <p>
                            <a href="/stuff">Stuff</a>
                        </p>
                    </div>
                </html
                EOHTML
            end

            it 'stops parsing then it finds a matching element' do
                expect(document.descendants.map(&:name)).to eq [:html, :div]
            end

            context 'when multiple elements are specified' do
                let(:options) { super().merge( stop_on_first: [ 'div', 'a' ] ) }

                it 'stops on the first one' do
                    expect(document.descendants.map(&:name)).to eq [:html, :div]
                end
            end
        end
    end

    describe '#document' do
        it 'returns the document' do
            expect(document).to be_kind_of Arachni::Parser::Document
        end
    end
end
