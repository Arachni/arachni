shared_examples_for 'with_node' do |html|
    it_should_behave_like 'with_source', html

    let(:with_node) do
        dupped = subject.dup
        dupped.source = html
        dupped
    end

    describe '#node' do
        it 'returns the set node' do
            node = with_node.node
            node.is_a?( Nokogiri::XML::Element ).should be_true
            node.to_s.should == Nokogiri::HTML.fragment( html ).to_s
        end
    end

    describe '#dup' do
        let(:dupped) { with_node.dup }

        it 'preserves #node' do
            dupped.node.to_s.should == with_node.node.to_s
        end
    end
end
