shared_examples_for 'with_scope' do |html|

    let(:with_scope) do
        # Make sure the scope has been loaded.
        subject.scope
        subject
    end

    describe '#to_rpc_data' do
        let(:data) { with_scope.to_rpc_data }

        it "does not include 'scope'" do
            data.should_not include 'scope'
        end
    end

    describe '#scope' do
        it 'returns scope' do
            subject.scope.should be_kind_of described_class::Scope
        end
    end
end
