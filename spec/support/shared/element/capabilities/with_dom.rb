shared_examples_for 'with_dom' do |html = nil|

    let(:with_node) do
        dupped = subject.dup
        dupped.html = html
        dupped
    end

    it "returns #{described_class::DOM}" do
        with_node.dom.should be_kind_of described_class::DOM
    end

    describe '#dup' do
        let(:dupped) { with_node.dup }

        it 'preserves #dom' do
            dupped.dom.should == with_node.dom
        end
    end
end
