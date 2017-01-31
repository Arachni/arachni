require 'spec_helper'

describe Arachni::Parser::WithChildren::Search do
    let(:options) do
        {}
    end
    subject { Arachni::Parser.parse( html, options ) }
    let(:html) do
        <<-EOHTML
        <html>
            <div id="my-id">
                <!-- My comment -->
                <p class="my-class">
                    <a href="/stuff">
                        <span data-id='deepest'>Deepest</span>
                    </a>
                </p>

                <span id='second-span'>Second span</span>

                My text
            </div>
        </html>
        EOHTML
    end

    def summarize( n )
        if n.is_a? Arachni::Parser::Nodes::Element
            [n.name, n.attributes]
        else
            [n.class, n.value]
        end
    end

    describe '#traverse' do
        it 'passes each descendant node to the block' do
            nodes = []

            subject.traverse do |n|
                nodes << summarize( n )
            end

            expect(nodes).to eq([
                [:html, {}],
                [:div, {"id"=>"my-id"}],
                [Arachni::Parser::Nodes::Comment, "My comment"],
                [:p, {"class"=>"my-class"}],
                [:a, {"href"=>"/stuff"}],
                [:span, {"data-id"=>"deepest"}],
                [Arachni::Parser::Nodes::Text, "Deepest"],
                [:span, {"id"=>"second-span"}],
                [Arachni::Parser::Nodes::Text, "Second span"],
                [Arachni::Parser::Nodes::Text, "My text"]
            ])

            nodes = []
            subject.children.first.children.first.children[1].traverse do |n|
                nodes << summarize( n )
            end

            expect(nodes).to eq([
                [:a, {"href"=>"/stuff"}],
                [:span, {"data-id"=>"deepest"}],
                [Arachni::Parser::Nodes::Text, "Deepest"]
            ])
        end
    end

    describe '#descendants' do
        it 'returns all descendants' do
            nodes = subject.descendants.map do |n|
                summarize n
            end

            expect(nodes).to eq([
                [:html, {}],
                [:div, {"id"=>"my-id"}],
                [Arachni::Parser::Nodes::Comment, "My comment"],
                [:p, {"class"=>"my-class"}],
                [:a, {"href"=>"/stuff"}],
                [:span, {"data-id"=>"deepest"}],
                [Arachni::Parser::Nodes::Text, "Deepest"],
                [:span, {"id"=>"second-span"}],
                [Arachni::Parser::Nodes::Text, "Second span"],
                [Arachni::Parser::Nodes::Text, "My text"]
            ])

            nodes = []
            subject.children.first.children.first.children[1].descendants.each do |n|
                nodes << summarize( n )
            end

            expect(nodes).to eq([
                [:a, {"href"=>"/stuff"}],
                [:span, {"data-id"=>"deepest"}],
                [Arachni::Parser::Nodes::Text, "Deepest"]
            ])
        end
    end

    describe '#nodes_by_name' do
        it 'returns all descendant nodes that have the given tag name' do
            nodes = subject.nodes_by_name( :span ).map { |n| summarize n }
            expect(nodes).to eq([
                [:span, {"data-id"=>"deepest"}],
                [:span, {"id"=>"second-span"}]
            ])

            nodes = subject.nodes_by_name( :a ).first.
                nodes_by_name( :span ).map { |n| summarize n }

            expect(nodes).to eq([
                [:span, {"data-id"=>"deepest"}]
            ])
        end
    end

    describe '#nodes_by_names' do
        it 'returns all descendant nodes that have the given tag names' do
            nodes = subject.nodes_by_names( :span, :a ).map { |n| summarize n }
            expect(nodes).to eq([
                [:span, {"data-id"=>"deepest"}],
                [:span, {"id"=>"second-span"}],
                [:a, {"href"=>"/stuff"}]
            ])
        end
    end

    describe '#nodes_by_attribute_name' do
        it 'returns all descendant nodes that have the given attribute name' do
            nodes = subject.nodes_by_attribute_name( 'data-id' ).map { |n| summarize n }
            expect(nodes).to eq([
                [:span, {"data-id"=>"deepest"}],
            ])
        end
    end

    describe '#nodes_by_attribute_name_and_value' do
        it 'returns all descendant nodes that have the given attribute name' do
            nodes = subject.nodes_by_attribute_name_and_value( 'id', 'second-span' ).map { |n| summarize n }
            expect(nodes).to eq([
                [:span, {"id"=>"second-span"}],
            ])
        end
    end
end
