shared_examples_for 'with_source' do |source|

    let(:with_source) do
        dupped = subject.dup
        dupped.source = source if source
        dupped
    end

    describe '#to_rpc_data' do
        let(:data) { with_source.to_rpc_data }

        it "includes 'source'" do
            data['source'].should == with_source.source
        end
    end

    describe '#source=' do
        context 'when given' do
            context String do
                let(:string) { 'stuff' }

                it 'recodes it' do
                    expect(string).to receive(:recode)
                    with_source.source = string
                end

                it 'sets the #source' do
                    with_source.source = string
                    with_source.source.should == string
                end
            end

            context 'nil' do
                it 'sets the #html' do
                    with_source.source = nil
                    with_source.source.should be_nil
                end
            end
        end
    end

    describe '#to_h' do
        it "includes 'source'" do
            subject.to_h[:source].should == subject.source
        end
    end

    describe '#dup' do
        let(:dupped) { with_source.dup }

        it 'preserves #source' do
            dupped.source.should == with_source.source
        end
    end
end
