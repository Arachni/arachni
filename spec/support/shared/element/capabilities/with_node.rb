shared_examples_for 'with_node' do |html|
    it_should_behave_like 'with_source', html

    let(:with_node) do
        subject.dup
    end

    describe '#node' do
        it 'returns the set node' do
            node = with_node.node
            expect(node.is_a?( Arachni::Parser::Nodes::Element )).to be_truthy
            expect(node.to_s).to eq(Arachni::Parser.parse_fragment( with_node.source ).to_s)
        end
    end

    describe '#dup' do
        let(:dupped) { with_node.dup }

        it 'preserves #node' do
            expect(dupped.node.to_s).to eq(with_node.node.to_s)
        end
    end
end
