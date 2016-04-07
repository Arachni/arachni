shared_examples_for 'inputtable' do |options = {}|

    let( :opts ) do
        { single_input: false }.merge( options )
    end

    let(:inputs) do
        return opts[:inputs] if opts[:inputs]

        if opts[:single_input]
            { 'input1' => 'value1' }
        else
            {
                'input1' => 'value1',
                'input2' => 'value2'
            }
        end
    end

    let(:sym_key_inputs) { inputs.my_symbolize_keys }

    let(:valid_key) { keys.first.to_s }

    let(:keys) do
        subject.inputs.keys
    end

    let(:sym_keys) do
        keys.map(&:to_sym)
    end

    let(:non_existent_keys) do
        inputs.keys.map { |k| "#{k}1" }
    end

    let(:non_existent_sym_keys) do
        non_existent_keys.map(&:to_sym)
    end

    subject do
        begin
            inputtable
        rescue
            described_class.new( url: url, inputs: inputs )
        end
    end

    it "supports #{Arachni::RPC::Serializer}" do
        expect(subject).to eq(Arachni::RPC::Serializer.deep_clone( subject ))
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        %w(inputs default_inputs raw_inputs).each do |attribute|
            it "includes '#{attribute}'" do
                expect(data[attribute]).to eq(subject.send( attribute ))
            end
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { subject.class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(inputs default_inputs raw_inputs).each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored.send( attribute )).to eq(subject.send( attribute ))
            end
        end
    end

    describe '#reset' do
        it 'returns the element to its original state' do
            orig = subject.dup

            k, v = orig.inputs.keys.first, 'value'

            subject.raw_inputs << k
            subject.update( k => v )

            expect(subject.inputs).not_to eq(orig.inputs)

            subject.reset

            expect(subject.inputs).to eq(orig.inputs)
            expect(subject.raw_inputs).to be_empty
        end
    end

    describe '#has_inputs?' do
        context 'when the given inputs are' do
            context 'variable arguments' do
                context 'when it has the given inputs' do
                    it 'returns true' do
                        keys.each do |k|
                            expect(subject.has_inputs?( k.to_s.to_sym )).to be_truthy
                            expect(subject.has_inputs?( k.to_s )).to be_truthy
                        end

                        expect(subject.has_inputs?( *sym_keys )).to be_truthy
                        expect(subject.has_inputs?( *keys )).to be_truthy
                    end
                end
                context 'when it does not have the given inputs' do
                    it 'returns false' do
                        expect(subject.has_inputs?( *non_existent_sym_keys )).to be_falsey
                        expect(subject.has_inputs?( *non_existent_keys )).to be_falsey

                        expect(subject.has_inputs?( non_existent_keys.first )).to be_falsey
                    end
                end
            end

            context 'Array' do
                context 'when it has the given inputs' do
                    it 'returns true' do
                        expect(subject.has_inputs?( sym_keys )).to be_truthy
                        expect(subject.has_inputs?( keys )).to be_truthy
                    end
                end
                context 'when it does not have the given inputs' do
                    it 'returns false' do
                        expect(subject.has_inputs?( non_existent_sym_keys )).to be_falsey
                        expect(subject.has_inputs?( non_existent_keys )).to be_falsey
                    end
                end
            end

            context 'Hash' do
                context 'when it has the given inputs (names and values)' do
                    it 'returns true' do
                        expect(subject.has_inputs?( subject.inputs )).to be_truthy
                        expect(subject.has_inputs?( subject.inputs.my_symbolize_keys )).to be_truthy
                    end
                end
                context 'when it does not have the given inputs' do
                    it 'returns false' do
                        expect(subject.has_inputs?(
                            inputs.keys.first => "#{inputs.values.first} 1"
                        )).to be_falsey
                    end
                end
            end
        end
    end

    describe '#inputs' do
        it 'is frozen' do
            expect(subject.inputs).to be_frozen
        end
    end

    describe '#inputtable_id' do
        before do
            allow_any_instance_of(described_class).to receive(:valid_input_name?) { true }
            allow_any_instance_of(described_class).to receive(:valid_input_value?) { true }
        end

        it 'takes into account input names' do
            e = subject.dup
            e.inputs = { 1 => 2 }

            c = subject.dup
            c.inputs = { 1 => 2 }

            expect(e.inputtable_id).to eq(c.inputtable_id)

            e = subject.dup
            e.inputs = { 1 => 2 }

            c = subject.dup
            c.inputs = { 2 => 2 }

            expect(e.inputtable_id).not_to eq(c.inputtable_id)
        end

        it 'takes into account raw inputs' do
            e = subject.dup
            e.inputs = { 1 => 2, 3 => 4 }
            e.raw_inputs = [1]

            c = subject.dup
            c.inputs = { 1 => 2, 3 => 4 }
            c.raw_inputs = [1]

            expect(e.inputtable_id).to eq(c.inputtable_id)

            e = subject.dup
            e.inputs = { 1 => 2, 3 => 4 }
            e.raw_inputs = [1]

            c = subject.dup
            e.inputs = { 1 => 2, 3 => 4 }
            e.raw_inputs = [2]

            expect(e.inputtable_id).not_to eq(c.inputtable_id)
        end

        it 'takes into account input values' do
            e = subject.dup
            e.inputs = { 1 => 2 }

            c = subject.dup
            c.inputs = { 1 => 2 }

            expect(e.inputtable_id).to eq(c.inputtable_id)

            e = subject.dup
            e.inputs = { 1 => 1 }

            c = subject.dup
            c.inputs = { 1 => 2 }

            expect(e.inputtable_id).not_to eq(c.inputtable_id)
        end

        it 'ignores input order', if: !options[:single_input] do
            e = subject.dup
            e.inputs = { 1 => 2, 3 => 4 }

            c = subject.dup
            c.inputs = { 3 => 4, 1 => 2 }

            expect(e.inputtable_id).to eq(c.inputtable_id)
        end
    end

    describe '#raw_inputs=' do
        it 'converts all inputs to strings' do
            subject.raw_inputs = [valid_key.to_sym]
            expect(subject.raw_inputs).to eq [valid_key.to_s]
        end

        context 'when a name contains invalid data' do
            it "raises #{Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Name}" do
                allow(subject).to receive(:valid_input_data?) { |data| data != valid_key }

                expect do
                    subject.raw_inputs = [ valid_key ]
                end.to raise_error Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Name
            end
        end

        context 'when a name is invalid' do
            it "raises #{Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Name}" do
                allow(subject).to receive(:valid_input_name?) { false }

                expect do
                    subject.raw_inputs = [ valid_key ]
                end.to raise_error Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Name
            end
        end
    end

    describe '#raw_input?' do
        context 'if the name is in #raw_inputs' do
            it 'returns true' do
                subject.raw_inputs = [valid_key]
                expect(subject.raw_input?( valid_key )).to be_truthy
            end
        end

        context 'if the name is not in #raw_inputs' do
            it 'returns false' do
                subject.raw_inputs = []
                expect(subject.raw_input?( valid_key )).to be_falsey
            end
        end
    end

    describe '#inputs=' do
        it 'assigns a hash of auditable inputs' do
            a = subject.dup
            a.inputs = { valid_key => 'my val' }
            expect(a.inputs).to eq({ valid_key => 'my val' })
        end

        it 'converts all inputs to strings',
           if: described_class != Arachni::Element::JSON do

            subject.inputs = { valid_key.to_sym => nil }
            expect(subject.inputs).to eq({ valid_key => '' })
        end

        context 'when the input name' do
            context 'contains invalid data' do
                it "raises #{Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Name}" do
                    allow(subject).to receive(:valid_input_data?) { |data| data != valid_key }

                    expect do
                        subject.inputs = { valid_key => 'blah' }
                    end.to raise_error Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Name
                end
            end

            context 'is invalid' do
                it "raises #{Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Name}" do
                    allow(subject).to receive(:valid_input_name?) { false }

                    expect do
                        subject.inputs = { valid_key => 'blah' }
                    end.to raise_error Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Name
                end
            end
        end

        context 'when the input value' do
            context 'contains invalid data' do
                it "raises #{Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Value}" do
                    allow(subject).to receive(:valid_input_data?) { |data| data != 'blah' }

                    expect do
                        subject.inputs = { valid_key => 'blah' }
                    end.to raise_error Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Value
                end
            end

            context 'is invalid' do
                it "raises #{Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Value}" do
                    allow(subject).to receive(:valid_input_value?) { false }

                    expect do
                        subject.inputs = { valid_key => 'blah' }
                    end.to raise_error Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Value
                end
            end
        end
    end

    describe '#valid_input_name_data?' do
        it 'returns true' do
            expect(subject.valid_input_name_data?( valid_key )).to be_truthy
        end

        context 'when the input name' do
            context 'contains invalid data' do
                it 'returns false' do
                    allow(subject).to receive(:valid_input_data?) { false }
                    expect(subject.valid_input_name_data?( valid_key )).to be_falsey
                end
            end

            context 'is invalid' do
                it 'returns false' do
                    allow(subject).to receive(:valid_input_name?) { false }
                    expect(subject.valid_input_name_data?( valid_key )).to be_falsey
                end
            end
        end
    end

    describe '#valid_input_value_data?' do
        it 'returns true' do
            expect(subject.valid_input_value_data?( 'blah' )).to be_truthy
        end

        context 'when the input value' do
            context 'contains invalid data' do
                it 'returns false' do
                    allow(subject).to receive(:valid_input_data?) { false }
                    expect(subject.valid_input_value_data?( 'blah' )).to be_falsey
                end
            end

            context 'is invalid' do
                it 'returns false' do
                    allow(subject).to receive(:valid_input_value?) { false }
                    expect(subject.valid_input_value_data?( 'blah' )).to be_falsey
                end
            end
        end
    end

    describe '#update' do
        it 'updates the auditable inputs using the given hash' do
            a = subject.dup

            updates = keys.inject({}) { |h, k| h.merge!( k => "#{k} val")}

            a.update( updates )
            expect(a.inputs).to eq(updates)
        end

        it 'converts all inputs to strings',
           if: described_class != Arachni::Element::JSON do

            subject.inputs = { valid_key => 'stuff' }
            subject.update( { valid_key => nil } )
            expect(subject.inputs).to eq({ valid_key => '' })
        end

        it 'returns self' do
            expect(subject.update({})).to eq(subject)
        end

        context 'when the input name is invalid' do
            it "raises #{Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Name}" do
                allow(subject).to receive(:valid_input_name?) { false }

                expect do
                    subject.update valid_key => 'blah'
                end.to raise_error Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Name
            end
        end

        context 'when the input value is invalid' do
            it "raises #{Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Value}" do
                allow(subject).to receive(:valid_input_value?) { false }

                expect do
                    subject.update valid_key => 'blah'
                end.to raise_error Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Value
            end
        end
    end

    describe '#updated?' do
        context 'when the inputs have been updated' do
            it 'returns true' do
                [
                    { valid_key => 'val12345' },
                    { valid_key => 'val2456' }
                ].each do |updates|
                    d = subject.dup
                    d.update( updates )
                    expect(d).to be_updated
                end
            end
        end

        context 'when the inputs have not been updated' do
            it 'returns false' do
                d = subject.dup

                expect(d).to_not be_updated

                d.update( subject.inputs )
                expect(d).to_not be_updated
            end
        end
    end

    describe '#changes' do
        it 'returns the changes the inputs have sustained' do
            [
                { valid_key => 'val1' },
                { valid_key => 'val2' },
                {}
            ].each do |updates|
                d = subject.dup
                d.update( updates )
                expect(d.changes).to eq(updates)
            end
        end
    end

    describe '#[]' do
        it ' serves as a reader to the #auditable hash' do
            expect(subject[valid_key]).to eq(subject.inputs[valid_key])
        end
    end

    describe '#[]=' do
        it 'serves as a writer to the #inputs hash' do
            subject[valid_key] = 'val1'
            expect(subject[valid_key]).to eq('val1')
            expect(subject[valid_key]).to eq(subject.inputs[valid_key])
        end

        context 'when the input name is invalid' do
            it "raises #{Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Name}" do
                allow(subject).to receive(:valid_input_name?) { false }

                expect do
                    subject[valid_key] = 'blah'
                end.to raise_error Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Name
            end
        end

        context 'when the input value is invalid' do
            it "raises #{Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Value}" do
                allow(subject).to receive(:valid_input_value?) { false }

                expect do
                    subject[valid_key] = 'blah'
                end.to raise_error Arachni::Element::Capabilities::Inputtable::Error::InvalidData::Value
            end
        end
    end

    describe '#try_input' do
        context 'when the operation is successful' do
            it 'returns true' do
                expect(subject.try_input do
                    subject.inputs = subject.inputs
                    nil
                end).to be_truthy
            end
        end

        context 'when the operation fails' do
            context 'due to an invalid name' do
                it 'returns false' do
                    allow(subject).to receive(:valid_input_name?) { false }

                    expect(subject.try_input do
                        subject.inputs = inputs
                        true
                    end).to be_falsey
                end
            end
            context 'due to an invalid value' do
                it 'returns false' do
                    allow(subject).to receive(:valid_input_value?) { false }

                    expect(subject.try_input do
                        subject.inputs = inputs
                        true
                    end).to be_falsey
                end
            end
        end
    end

    describe '#default_inputs' do
        it 'should be frozen' do
            expect(subject.default_inputs).to be_frozen
        end

        context 'when #inputs' do
            context 'has been modified' do
                it 'returns original input name/vals' do
                    orig_auditable = subject.inputs.dup
                    subject.inputs = {}
                    expect(subject.default_inputs).to eq(orig_auditable)
                end
            end
            context 'has not been modified' do
                it 'returns #inputs' do
                    expect(subject.default_inputs).to eq(subject.inputs)
                end
            end
        end
    end

    describe '#dup' do
        it 'preserves #inputs' do
            dup = subject.dup
            expect(dup.inputs).to eq(subject.inputs)

            dup[valid_key] = 'blah'
            expect(subject.inputs[valid_key]).not_to eq('blah')

            expect(dup.dup[valid_key]).to eq('blah')
        end
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            subject.raw_inputs = [ subject.inputs.keys.first ]

            hash = subject.to_h
            expect(hash[:inputs]).to         eq(subject.inputs)
            expect(hash[:default_inputs]).to eq(subject.default_inputs)
            expect(hash[:raw_inputs]).to eq(subject.raw_inputs)
        end
    end

end
