shared_examples_for 'sink' do
    %w(trace).each do |m|
        it { should respond_to m }
        it { should respond_to "#{m}=" }
    end

    it "supports #{Arachni::RPC::Serializer}" do
        subject.should == Arachni::RPC::Serializer.deep_clone( subject )
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "includes 'trace'" do
            data[:trace].should == subject.trace.map(&:to_rpc_data)
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(trace).each do |attribute|
            it "restores '#{attribute}'" do
                restored.send( attribute ).should == subject.send( attribute )
            end
        end
    end

end
