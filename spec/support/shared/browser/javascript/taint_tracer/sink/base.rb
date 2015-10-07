shared_examples_for 'sink' do
    %w(trace).each do |m|
        it { is_expected.to respond_to m }
        it { is_expected.to respond_to "#{m}=" }
    end

    it "supports #{Arachni::RPC::Serializer}" do
        expect(subject).to eq(Arachni::RPC::Serializer.deep_clone( subject ))
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "includes 'trace'" do
            expect(data[:trace]).to eq(subject.trace.map(&:to_rpc_data))
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(trace).each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored.send( attribute )).to eq(subject.send( attribute ))
            end
        end
    end

    describe '#to_h' do
        it 'converts #trace data to hashes' do
            expect(subject.to_h[:trace]).to eq([Factory[:frame_data]])
        end
    end

end
