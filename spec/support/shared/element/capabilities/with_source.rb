shared_examples_for 'with_source' do |source|

    let(:with_source) do
        subject.dup
    end

    describe '#to_rpc_data' do
        let(:data) { with_source.to_rpc_data }

        it "includes 'source'" do
            expect(data['source']).to eq(with_source.source)
        end
    end

    describe '#source=' do
        context 'when given' do
            context 'String' do
                let(:string) { 'stuff' }

                it 'sets the #source' do
                    with_source.source = string
                    expect(with_source.source).to eq(string)
                end
            end

            context 'nil' do
                it 'sets the #html' do
                    with_source.source = nil
                    expect(with_source.source).to be_nil
                end
            end
        end
    end

    describe '#to_h' do
        it "includes 'source'" do
            expect(subject.to_h[:source]).to eq(subject.source)
        end
    end

    describe '#dup' do
        let(:dupped) { with_source.dup }

        it 'preserves #source' do
            expect(dupped.source).to eq(with_source.source)
        end
    end
end
