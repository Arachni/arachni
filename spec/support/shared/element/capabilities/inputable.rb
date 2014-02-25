shared_examples_for 'inputable' do |options = {}|

    let( :opts ) do
        { single_input: false }.merge( options )
    end

    let(:inputs) do
        if opts[:single_input]
            { 'input1' => 'value1' }
        else
            {
                'input1' => 'value1',
                'input2' => 'value2'
            }
        end
    end

    let(:keys) do
        inputs.keys
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

    let(:inputable) do
        subject.inputs = inputs
        subject.instance_variable_set(:@default_inputs, inputs)
        subject
    end

    describe '#has_inputs?' do
        describe '#reset' do
            it 'returns the element to its original state' do
                orig = inputable.dup

                k, v = orig.inputs.keys.first, 'value'

                inputable.update( k => v )
                inputable.affected_input_name = k
                inputable.affected_input_value = v
                inputable.seed = v

                inputable.inputs.should_not == orig.inputs
                inputable.affected_input_name.should_not == orig.affected_input_name
                inputable.affected_input_value.should_not == orig.affected_input_value
                inputable.seed.should_not == orig.seed

                inputable.reset

                inputable.inputs.should == orig.inputs

                inputable.affected_input_name.should == orig.affected_input_name
                inputable.affected_input_name.should be_nil

                inputable.affected_input_value.should == orig.affected_input_value
                inputable.affected_input_value.should be_nil

                inputable.seed.should == orig.seed
                inputable.seed.should be_nil
            end
        end

        context 'when the given inputs are' do
            context 'variable arguments' do
                context 'when it has the given inputs' do
                    it 'returns true' do
                        keys.each do |k|
                            inputable.has_inputs?( k.to_s.to_sym ).should be_true
                            inputable.has_inputs?( k.to_s ).should be_true
                        end

                        inputable.has_inputs?( *sym_keys ).should be_true
                        inputable.has_inputs?( *keys ).should be_true
                    end
                end
                context 'when it does not have the given inputs' do
                    it 'returns false' do
                        inputable.has_inputs?( *non_existent_sym_keys ).should be_false
                        inputable.has_inputs?( *non_existent_keys ).should be_false

                        inputable.has_inputs?( non_existent_keys.first ).should be_false
                    end
                end
            end

            context Array do
                context 'when it has the given inputs' do
                    it 'returns true' do
                        inputable.has_inputs?( sym_keys ).should be_true
                        inputable.has_inputs?( keys ).should be_true
                    end
                end
                context 'when it does not have the given inputs' do
                    it 'returns false' do
                        inputable.has_inputs?( non_existent_sym_keys ).should be_false
                        inputable.has_inputs?( non_existent_keys ).should be_false
                    end
                end
            end

            context Hash do
                context 'when it has the given inputs (names and values)' do
                    it 'returns true' do
                        hash     = inputable.inputs.
                            inject( {} ) { |h, (k, v)| h[k] = v; h}

                        hash_sym = inputable.inputs.
                            inject( {} ) { |h, (k, v)| h[k.to_sym] = v; h}

                        inputable.has_inputs?( hash_sym ).should be_true
                        inputable.has_inputs?( hash ).should be_true
                    end
                end
                context 'when it does not have the given inputs' do
                    it 'returns false' do
                        hash     = inputable.inputs.
                            inject( {} ) { |h, (k, v)| h[k] = "#{v}1"; h}

                        hash_sym = inputable.inputs.
                            inject( {} ) { |h, (k, v)| h[k.to_sym] = "#{v}1"; h}

                        inputable.has_inputs?( hash_sym ).should be_false
                        inputable.has_inputs?( hash ).should be_false
                    end
                end
            end
        end
    end

    describe '#inputs' do
        it 'returns a frozen hash of auditable inputs' do
            inputable.inputs.should be_frozen
        end
    end

    describe '#inputs=' do
        it 'assigns a hash of auditable inputs' do
            a = inputable.dup
            a.inputs = { 'param1' => 'val1' }
            a.inputs.should == { 'param1' => 'val1' }
            a.should_not == inputable
        end

        it 'converts all inputs to strings' do
            inputable.inputs = { key: nil }
            inputable.inputs.should == { 'key' => '' }
        end
    end

    describe '#update' do
        it 'updates the auditable inputs using the given hash' do
            a = inputable.dup

            updates =   if opts[:single_input]
                            { 'input1' => 'val1' }
                        else
                            { 'input1' => 'val1', 'input2' => 'val3' }
                        end

            a.update( updates )
            a.inputs.should == updates

            if !opts[:single_input]
                c = a.dup
                c.update( stuff: '1' ).update( other_stuff: '2' )
                c['stuff'].should == '1'
                c['other_stuff'].should == '2'
            end
        end

        it 'converts all inputs to strings' do
            inputable.inputs = { 'key' => 'stuff' }
            inputable.update( { 'key' => nil } )
            inputable.inputs.should == { 'key' => '' }
        end

        it 'returns self' do
            inputable.update({}).should == inputable
        end
    end

    describe '#changes' do
        it 'returns the changes the inputs have sustained' do
            if !opts[:single_input]
                [
                    { 'input1' => 'val1', 'input2' => 'val2' },
                    { 'input2' => 'val3' },
                    { 'new stuff' => 'houa!' },
                    { 'new stuff' => 'houa!' },
                    {}
                ].each do |updates|
                    d = subject.dup
                    d.update( updates )
                    d.changes.should == updates
                end
            else
                [
                    { 'input1' => 'val1' },
                    { 'input1' => 'val2' },
                    {}
                ].each do |updates|
                    d = subject.dup
                    d.update( updates )
                    d.changes.should == updates
                end
            end
        end
    end

    describe '#[]' do
        it ' serves as a reader to the #auditable hash' do
            inputable['input1'].should == inputable.inputs['input1']
        end
    end

    describe '#[]=' do
        it 'serves as a writer to the #inputs hash' do
            inputable['input1'] = 'val1'
            inputable['input1'].should == 'val1'
            inputable['input1'].should == inputable.inputs['input1']
        end
    end

    describe '#default_inputs' do
        it 'should be frozen' do
            subject.default_inputs.should be_frozen
        end

        context 'when #inputs' do
            context 'has been modified' do
                it 'returns original input name/vals' do
                    orig_auditable = subject.inputs.dup
                    subject.inputs = {}
                    subject.default_inputs.should == orig_auditable
                end
            end
            context 'has not been modified' do
                it 'returns #inputs' do
                    subject.default_inputs.should == subject.inputs
                end
            end
        end
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            hash = inputable.to_h
            hash[:inputs].should         == inputable.inputs
            hash[:default_inputs].should == inputable.default_inputs
        end
    end

end
