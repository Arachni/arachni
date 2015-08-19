shared_examples_for 'with_scope' do

    let(:with_scope) do
        # Make sure the scope has been loaded.
        subject.scope
        subject
    end

    describe '#to_rpc_data' do
        let(:data) { with_scope.to_rpc_data }

        it "does not include 'scope'" do
            expect(data).not_to include 'scope'
        end
    end

    describe '#scope' do
        it 'returns scope' do
            expect(subject.scope).to be_kind_of described_class::Scope
        end
    end
end
