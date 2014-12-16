shared_examples_for 'mutable' do |options = {}|

    let(:opts) do
        {
            single_input:   false,
            supports_nulls: true
        }.merge( options )
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

    let(:seed) { 'my_seed' }
    let(:mutable) do
        if defined? super
            super()
        else
            s = subject.dup
            s.inputs = inputs
            s
        end
    end
    let(:mutation) do
        mutable.mutations( seed ).find { |m| m.mutation? }
    end

    it "supports #{Arachni::RPC::Serializer}" do
        mutation.should == Arachni::RPC::Serializer.deep_clone( mutation )
    end

    describe '#to_rpc_data' do
        let(:data) { mutation.to_rpc_data }

        %w(seed format affected_input_name).each do |attribute|
            it "includes '#{attribute}'" do
                data[attribute].should == mutation.send( attribute )
            end
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { mutation.class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( mutation ) }

        %w(seed format affected_input_name).each do |attribute|
            it "restores '#{attribute}'" do
                restored.send( attribute ).should == mutation.send( attribute )
            end
        end
    end

    describe '#mutation?' do
        context 'when the element has not been mutated' do
            it 'returns true' do
                mutable.mutation?.should be_false
            end
        end
        context 'when the element has been mutated' do
            it 'returns false' do
                mutable.mutations( seed ).first.mutation?.should be_true
            end
        end
    end

    describe '#affected_input_value' do
        it 'returns the value of the affected_input_name input' do
            elem = mutable.mutations( seed ).first
            elem.affected_input_value.should == seed
        end

        context 'when no input has been affected_input_name' do
            it 'returns nil' do
                mutable.affected_input_value.should be_nil
            end
        end
    end

    describe '#affected_input_value=' do
        it 'sets the value of the affected_input_name input' do
            elem = mutable.mutations( seed ).first
            elem.affected_input_value = 'stuff'
            elem.affected_input_value.should == 'stuff'
            elem.inputs.values.first.should == 'stuff'
        end
    end

    describe '#immutables' do
        it 'skips contained inputs' do
            input = mutable.inputs.keys.first

            mutable.immutables << input
            mutable.mutations( seed ).
                reject { |e| e.affected_input_name != input }.
                should be_empty

            mutable.immutables.clear
            mutable.mutations( seed ).
                reject { |e| e.affected_input_name != input }.
                should be_any
        end
    end

    describe '#mutations' do
        it 'mutates #inputs' do
            mutable.mutations( seed, skip_original: true ).each do |m|
                mutable.url.should == m.url
                mutable.action.should == m.action
                mutable.inputs.should_not == m.inputs
            end
        end

        it 'sets #affected_input_name to the name of the fuzzed input' do
            checked = false
            mutable.mutations( seed, skip_original: true ).each do |m|
                mutable.url.should == m.url
                mutable.action.should == m.action
                mutable.affected_input_name.should_not == m.affected_input_name
                m.inputs[m.affected_input_name].should include seed

                checked = true
            end

            checked.should be_true
        end

        context 'with no options' do
            it 'returns all combinations' do
                # We set the skip_original option because it only applies to forms.
                mutable.mutations( seed, skip_original: true ).size.should ==
                    (opts[:single_input] ? 4 : 8) / (opts[:supports_nulls] ? 1 : 2)
            end
        end

        context 'with option' do
            describe :respect_method,
                     if: !described_class.ancestors.include?(
                         Arachni::Element::Capabilities::Auditable::DOM
                     ) && described_class != Arachni::Element::JSON &&
                             described_class != Arachni::Element::XML do

                describe true do
                    it 'does not fuzz methods' do
                        respect_method = mutable.mutations( seed, respect_method: true )
                        respect_method.map{ |m| m.method }.uniq.should eq [mutable.method]
                    end
                end
                describe false do
                    it 'fuzzes methods' do
                        no_respect_method = mutable.mutations( seed, respect_method: false )
                        no_respect_method.map{ |m| m.method }.uniq.should eq [:get, :post]
                    end
                end
                describe 'nil' do
                    it 'does not fuzz methods' do
                        respect_method = mutable.mutations( seed )
                        respect_method.map{ |m| m.method }.uniq.should == [mutable.method]
                    end
                end
            end

            describe 'Options.audit.with_both_http_methods',
                     if: !described_class.ancestors.include?(
                         Arachni::Element::Capabilities::Auditable::DOM
                     ) && described_class != Arachni::Element::JSON &&
                        described_class != Arachni::Element::XML do

                it 'serves as the default value of :respect_method' do
                    Arachni::Options.audit.with_both_http_methods = true
                    no_respect_method = mutable.mutations( seed )

                    no_respect_method.map{ |m| m.method }.uniq.should eq [:get, :post]

                    Arachni::Options.audit.with_both_http_methods = false
                    respect_method = mutable.mutations( seed )

                    respect_method.map{ |m| m.method }.uniq.should == [mutable.method]
                end
            end

            describe :skip do
                it 'skips mutation of parameters with these names' do
                    mutable.mutations( seed, skip: [ 'input_one' ] )
                end
            end

            describe :fuzz_names,
                     if: !described_class.ancestors.include?(
                         Arachni::Element::Capabilities::Auditable::DOM
                     ) && described_class != Arachni::Element::LinkTemplate &&
                             described_class != Arachni::Element::XML do

                it 'uses the seed as a param name' do
                    mutable.mutations(
                        seed,
                        format:        [Arachni::Element::Capabilities::Mutable::Format::STRAIGHT],
                        fuzz_names:    true,
                        skip_original: true
                    ).select { |m| m.inputs.include? seed }.size.should > 0
                end

                context 'when the payload is not supported' do
                    context 'as a name'do
                        it 'skips the mutation' do
                            seed = 'payload'

                            mutable.mutations( seed, fuzz_names: true ).
                                select { |m| m.inputs.keys.include? seed }.
                                size.should > 0

                            described_class.any_instance.
                                stub(:valid_input_name_data?) { |name| name != seed }

                            mutable.mutations( seed, fuzz_names: true ).
                                select { |m| m.inputs.keys.include? seed }.
                                size.should == 0
                        end
                    end
                end
            end

            describe :format do
                describe 'Format::STRAIGHT' do
                    it 'injects the seed as is' do
                        m = mutable.mutations( seed,
                                                format: [Arachni::Element::Capabilities::Mutable::Format::STRAIGHT],
                                                skip_original: true ).first
                        m[m.affected_input_name].should == seed
                    end
                end
                describe 'Format::APPEND' do
                    it 'appends the seed to the current value' do
                        m = mutable.mutations( seed,
                                                format: [Arachni::Element::Capabilities::Mutable::Format::APPEND],
                                                skip_original: true ).first
                        m[m.affected_input_name].should == inputs[m.affected_input_name] + seed
                    end
                end
                describe 'Format::NULL' do
                    it 'terminates the string with a null character',
                       if: described_class != Arachni::Element::Header &&
                               described_class.is_a?( Arachni::Element::Capabilities::Auditable::DOM ) do

                        m = mutable.mutations( seed,
                                                format: [Arachni::Element::Capabilities::Mutable::Format::NULL],
                                                skip_original: true ).first
                        m[m.affected_input_name].should == seed + "\0"
                    end
                end
                describe 'Format::SEMICOLON' do
                    it 'prepends the seed with a semicolon' do
                        m = mutable.mutations( seed,
                                                format: [Arachni::Element::Capabilities::Mutable::Format::SEMICOLON],
                                                skip_original: true ).first
                        m[m.affected_input_name].should == ';' + seed
                    end
                end
                describe 'Format::APPEND | Format::NULL' do
                    it 'appends the seed and terminate the string with a null character',
                       if: described_class != Arachni::Element::Header &&
                            described_class.is_a?( Arachni::Element::Capabilities::Auditable::DOM ) do

                        format = [Arachni::Element::Capabilities::Mutable::Format::APPEND |
                                      Arachni::Element::Capabilities::Mutable::Format::NULL]
                        m = mutable.mutations( seed, format: format, skip_original: true  ).first
                        m[m.affected_input_name].should == inputs[m.affected_input_name] + seed + "\0"
                    end
                end
            end
        end

        context 'when the payload is not supported' do
            it 'returns an empty array' do
                described_class.any_instance.stub(:valid_input_data?) { |i| i != '1' }

                mutable.mutations('1', skip_original: true ).size.should == 0
            end

            context 'as a value' do
                it 'skips the mutation' do
                    mutable.mutations(seed).
                        select { |m| m.affected_input_value.include? seed }.
                        size.should > 0

                    described_class.any_instance.
                        stub(:valid_input_value_data?) { |value| value.include? seed }

                    mutable.mutations('1').
                        select { |m| m.affected_input_value.include? seed }.
                        size.should == 0
                end
            end
        end
    end

    describe '#affected_input_name' do
        it 'returns the name of the mutated input' do
            m = mutable.mutations( seed,
                                    format: [Arachni::Element::Capabilities::Mutable::Format::STRAIGHT],
                                    skip_original: true ).first
            m.inputs[m.affected_input_name].should_not == inputs[m.affected_input_name]
        end

        context 'when no input has been affected_input_name' do
            it 'returns nil' do
                mutable.affected_input_name.should be_nil
            end
        end
    end

    describe '#seed' do
        it 'returns the original seed' do
            seeds  = []
            values = []

            mutable.each_mutation( seed, skip_original: true ) do |m|
                seeds  << m.seed
                values << m.affected_input_value
            end

            seeds.sort.uniq.should == %w(my_seed)
        end
    end

    describe '#dup' do
        let(:dupped) { mutation.dup }

        it 'preserves #seed' do
            dupped.seed.should == mutation.seed
        end
        it 'preserves #affected_input_name' do
            dupped.affected_input_name.should == mutation.affected_input_name
        end
        it 'preserves #format' do
            dupped.format.should == mutation.format
        end
        it 'preserves #immutables' do
            mutation.immutables << 'stuff'
            dupped.immutables.should == mutation.immutables
        end
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            hash = mutation.to_h
            hash[:affected_input_name].should == mutation.affected_input_name
            hash[:affected_input_value].should == mutation.affected_input_value
            hash[:seed].should == mutation.seed
        end

        context 'when the element is not a mutation' do
            it 'does not include mutation related data' do
                hash = mutable.to_h
                hash.should_not include :affected_input_name
                hash.should_not include :affected_input_value
                hash.should_not include :seed
            end
        end
    end

end
