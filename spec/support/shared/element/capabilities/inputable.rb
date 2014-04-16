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
            inputable
        rescue
            described_class.new( url: url, inputs: inputs )
        end
    end

    it "supports #{Arachni::Serializer}" do
        subject.should == Arachni::Serializer.load( Arachni::Serializer.dump( subject ) )
    end

    describe '#has_inputs?' do
        describe '#reset' do
            it 'returns the element to its original state' do
                orig = subject.dup

                k, v = orig.inputs.keys.first, 'value'

                subject.update( k => v )
                subject.affected_input_name = k
                subject.affected_input_value = v
                subject.seed = v

                subject.inputs.should_not == orig.inputs
                subject.affected_input_name.should_not == orig.affected_input_name
                subject.affected_input_value.should_not == orig.affected_input_value
                subject.seed.should_not == orig.seed

                subject.reset

                subject.inputs.should == orig.inputs

                subject.affected_input_name.should == orig.affected_input_name
                subject.affected_input_name.should be_nil

                subject.affected_input_value.should == orig.affected_input_value
                subject.affected_input_value.should be_nil

                subject.seed.should == orig.seed
                subject.seed.should be_nil
            end
        end

        context 'when the given inputs are' do
            context 'variable arguments' do
                context 'when it has the given inputs' do
                    it 'returns true' do
                        keys.each do |k|
                            subject.has_inputs?( k.to_s.to_sym ).should be_true
                            subject.has_inputs?( k.to_s ).should be_true
                        end

                        subject.has_inputs?( *sym_keys ).should be_true
                        subject.has_inputs?( *keys ).should be_true
                    end
                end
                context 'when it does not have the given inputs' do
                    it 'returns false' do
                        subject.has_inputs?( *non_existent_sym_keys ).should be_false
                        subject.has_inputs?( *non_existent_keys ).should be_false

                        subject.has_inputs?( non_existent_keys.first ).should be_false
                    end
                end
            end

            context Array do
                context 'when it has the given inputs' do
                    it 'returns true' do
                        subject.has_inputs?( sym_keys ).should be_true
                        subject.has_inputs?( keys ).should be_true
                    end
                end
                context 'when it does not have the given inputs' do
                    it 'returns false' do
                        subject.has_inputs?( non_existent_sym_keys ).should be_false
                        subject.has_inputs?( non_existent_keys ).should be_false
                    end
                end
            end

            context Hash do
                context 'when it has the given inputs (names and values)' do
                    it 'returns true' do
                        subject.has_inputs?( sym_keys ).should be_true
                        subject.has_inputs?( keys ).should be_true
                    end
                end
                context 'when it does not have the given inputs' do
                    it 'returns false' do
                        subject.has_inputs?( non_existent_sym_keys ).should be_false
                        subject.has_inputs?( non_existent_keys ).should be_false
                    end
                end
            end
        end
    end

    describe '#inputs' do
        it 'returns a frozen hash of auditable inputs' do
            subject.inputs.should be_frozen
        end
    end

    describe '#inputs=' do
        it 'assigns a hash of auditable inputs' do
            a = subject.dup
            a.inputs = { 'param1' => 'val1' }
            a.inputs.should == { 'param1' => 'val1' }
            a.should_not == subject
        end

        it 'converts all inputs to strings' do
            subject.inputs = { key: nil }
            subject.inputs.should == { 'key' => '' }
        end
    end

    describe '#update' do
        it 'updates the auditable inputs using the given hash' do
            a = subject.dup

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
            subject.inputs = { 'key' => 'stuff' }
            subject.update( { 'key' => nil } )
            subject.inputs.should == { 'key' => '' }
        end

        it 'returns self' do
            subject.update({}).should == subject
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
            subject['input1'].should == subject.inputs['input1']
        end
    end

    describe '#[]=' do
        it 'serves as a writer to the #inputs hash' do
            subject['input1'] = 'val1'
            subject['input1'].should == 'val1'
            subject['input1'].should == subject.inputs['input1']
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

    describe '#dup' do
        it 'preserves #inputs' do
            dup = subject.dup
            dup.inputs.should == subject.inputs

            if opts[:single_input]
                dup[:input1] = 'blah'
                subject.inputs['input1'].should_not == 'blah'
                dup.should_not == subject

                dup.dup[:input1].should == 'blah'
            else
                dup[:stuff] = 'blah'
                subject.inputs.should_not include :stuff
                dup.should_not == subject

                dup.dup[:stuff].should == 'blah'
            end
        end
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            hash = subject.to_h
            hash[:inputs].should         == subject.inputs
            hash[:default_inputs].should == subject.default_inputs
        end
    end

end
