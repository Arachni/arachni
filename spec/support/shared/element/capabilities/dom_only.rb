shared_examples_for 'dom_only' do |source|
    it_should_behave_like 'element'
    it_should_behave_like 'inputtable'
    it_should_behave_like 'with_node'
    it_should_behave_like 'with_dom', source

    it "supports #{Arachni::RPC::Serializer}" do
        expect(subject).to eq(Arachni::RPC::Serializer.deep_clone( subject ))
    end

    describe '.new' do
        describe ':action' do
            it 'sets the #action' do
                expect(described_class.new( action: url ).action).to eq url
            end

            it 'sets the #url' do
                expect(described_class.new( action: url ).url).to eq url
            end
        end

        describe ':method' do
            it 'sets the #method' do
                expect(described_class.new(
                           action: url,
                           method: 'onclick'
                       ).method).to eq 'onclick'
            end
        end
    end

    describe '#mutation?' do
        it 'returns false' do
            expect(subject.mutation?).to be_falsey
        end
    end

    describe '#coverage_id' do
        it 'delegates to #dom' do
            allow(subject.dom).to receive(:coverage_id).and_return( 'stuff' )
            expect(subject.coverage_id).to eq "#{described_class.type}:stuff"
        end
    end

    describe '#coverage_hash' do
        it 'hashes #coverage_id' do
            expect(subject.coverage_hash).to eq subject.coverage_id.persistent_hash
        end
    end

    describe '#id' do
        it 'delegates to #dom' do
            allow(subject.dom).to receive(:id).and_return( 'stuff' )
            expect(subject.id).to eq "#{described_class.type}:stuff"
        end
    end

    describe '#type' do
        it "delegates to #{described_class}" do
            allow(described_class).to receive(:type).and_return( :stuff )
            expect(subject.type).to eq :stuff
        end
    end
end
