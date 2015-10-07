shared_examples_for 'option_group' do
    it { is_expected.to respond_to :to_h }

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it 'converts self to a serializable hash' do
            expect(data).to be_kind_of Hash

            expect(Arachni::RPC::Serializer.load(
                Arachni::RPC::Serializer.dump( data )
            )).to eq(data)
        end
    end

    described_class.defaults.each do |k, v|
        describe "##{k}" do
            it "defaults to #{v}" do
                expect(subject.instance_variable_get( "@#{k}".to_sym )).to eq(v)
                expect(subject.send( k )).to eq(v)
            end
        end
    end

    it 'honors default values for attributes' do
        subject.defaults.each do |k, v|
            subject.send "#{k}=", nil
            expect(subject.instance_variable_get( "@#{k}".to_sym )).to eq(v)
            expect(subject.send( k )).to eq(v)
        end
    end

    describe '#to_hash' do
        it 'returns a hash' do
            expect(subject.to_hash).to be_kind_of Hash
        end
    end

    describe '#to_h' do
        it 'returns a hash' do
            expect(subject.to_h).to be_kind_of Hash
        end

        it 'only includes attributes with accessors' do
            method = subject.methods.find { |m| m.to_s.end_with? '=' }
            if method == :=== || method == :==
                expect(subject.to_h).to be_empty
                next
            end

            subject.send( method, subject.defaults[method.to_s[0..-1].to_sym] )

            hash = subject.to_h
            expect(hash).to be_any
            hash.each do |k, v|
                expect(subject).to respond_to "#{k}="
            end
        end
    end

    describe '#update' do
        it 'updates self with the values of the given hash' do
            method = subject.methods.find { |m| m.to_s.end_with? '=' }
            next if method == :=== || method == :==

            method = method.to_s[0...-1].to_sym
            value  = subject.defaults[method.to_s[0..-1].to_sym]

            subject.update( { method => value } )
            expect(subject.send( method )).to eq(value)
        end

        it 'returns self' do
            expect(subject.update({})).to eq(subject)
        end
    end

    describe '#merge' do
        it 'updates self with the values of the given OptionGroup' do
            method = subject.methods.find { |m| m.to_s.end_with? '=' }
            next if method == :=== || method == :==

            method = method.to_s[0...-1].to_sym
            value  = subject.defaults[method.to_s[0..-1].to_sym]

            group = described_class.new
            group.update( { method => value } )

            subject.merge( group )
            expect(subject.send( method )).to eq(value)
        end

        it 'returns self' do
            group = described_class.new
            expect(subject.merge( group )).to eq(subject)
        end
    end
end
