shared_examples_for 'mutable' do |options = {}|

    let(:opts) do
        {
            single_input:   false,
            supports_nulls: true
        }.merge( options )
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

    let(:valid_key) { inputs.keys.first.to_s }

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
                mutable.mutations( seed, skip_original: true ).size.should ==
                    (inputs.size * 4) / (opts[:supports_nulls] ? 1 : 2)
            end
        end

        context 'with option' do
            describe :parameter_values do
                describe true do
                    it 'injects the payload into parameter values' do
                        mutable.mutations( seed, parameter_values: true ).
                            find { |m| m.affected_input_value.include? seed }.
                            should be_true
                    end
                end
                describe false do
                    it 'does not inject the payload into parameter values' do
                        mutable.mutations( seed, parameter_values: false ).
                            find { |m| m.affected_input_value.include? seed }.
                            should be_false
                    end
                end
                describe 'nil' do
                    it 'injects the payload into parameter names' do
                        mutable.mutations( seed ).
                            find { |m| m.affected_input_value.include? seed }.
                            should be_true
                    end
                end

                describe "#{Arachni::OptionGroups::Audit}#parameter_values" do
                    it 'serves as the default value of :parameter_values' do
                        Arachni::Options.audit.parameter_values = true
                        mutable.mutations( seed ).
                            find { |m| m.affected_input_value.include? seed }.
                            should be_true

                        Arachni::Options.audit.parameter_values = false
                        mutable.mutations( seed ).
                            find { |m| m.affected_input_value.include? seed }.
                            should be_false
                    end
                end
            end

            describe :with_extra_parameter,
                     if: !described_class.ancestors.include?(
                         Arachni::Element::Capabilities::Auditable::DOM
                     ) && described_class != Arachni::Element::LinkTemplate &&
                             described_class != Arachni::Element::XML do

                let(:extra_name) { described_class::EXTRA_NAME }

                describe true do
                    it 'injects the payload into an extra parameter' do
                        mutable.mutations( seed, with_extra_parameter: true ).
                            find { |m| m[extra_name].to_s.include? seed }.should be_true
                    end
                end
                describe false do
                    it 'does not inject the payload into an extra parameter' do
                        mutable.mutations( seed, with_extra_parameter: false ).
                            find { |m| m[extra_name].to_s.include? seed }.should be_false
                    end
                end
                describe 'nil' do
                    it 'does not inject the payload into an extra parameter' do
                        mutable.mutations( seed ).
                            find { |m| m[extra_name].to_s.include? seed }.should be_false
                    end
                end

                describe "#{Arachni::OptionGroups::Audit}#with_extra_parameter" do
                    it 'serves as the default value of :with_extra_parameter' do
                        Arachni::Options.audit.with_extra_parameter = true
                        mutable.mutations( seed ).
                            find { |m| m[extra_name].to_s.include? seed }.should be_true

                        Arachni::Options.audit.with_extra_parameter = false
                        mutable.mutations( seed ).
                            find { |m| m[extra_name].to_s.include? seed }.should be_false
                    end
                end
            end

            describe :with_both_http_methods,
                     if: !described_class.ancestors.include?(
                         Arachni::Element::Capabilities::Auditable::DOM
                     ) && described_class != Arachni::Element::JSON &&
                             described_class != Arachni::Element::XML do

                describe false do
                    it 'does not fuzz methods' do
                        mutable.mutations( seed, with_both_http_methods: false ).
                            map(&:method).uniq.should eq [mutable.method]
                    end
                end
                describe true do
                    it 'fuzzes methods' do
                        mutable.mutations( seed, with_both_http_methods: true ).
                            map(&:method).uniq.should eq [:get, :post]
                    end
                end
                describe 'nil' do
                    it 'does not fuzz methods' do
                        mutable.mutations( seed ).map(&:method).uniq.
                            should == [mutable.method]
                    end
                end

                describe "#{Arachni::OptionGroups::Audit}#with_both_http_methods" do
                    it 'serves as the default value of :with_both_http_methods' do
                        Arachni::Options.audit.with_both_http_methods = true
                        mutable.mutations( seed ).map(&:method).uniq.
                            should eq [:get, :post]

                        Arachni::Options.audit.with_both_http_methods = false
                        mutable.mutations( seed ).map(&:method).uniq.
                            should == [mutable.method]
                    end
                end
            end

            describe :parameter_names,
                     if: !described_class.ancestors.include?(
                         Arachni::Element::Capabilities::Auditable::DOM
                     ) && described_class != Arachni::Element::LinkTemplate &&
                             described_class != Arachni::Element::XML do

                describe true do
                    it 'uses the seed as a parameter name' do
                        mutable.mutations( seed, parameter_names: true ).
                            find { |m| m.inputs.keys.include? seed }.
                            should be_true
                    end
                end
                describe false do
                    it 'does not use the seed as a parameter name' do
                        mutable.class.any_instance.
                            stub(:valid_input_name_data?) { |name| name != seed }

                        mutable.mutations( seed, parameter_names: false ).
                            find { |m| m.inputs.keys.include? seed }.
                            should be_false
                    end
                end
                describe 'nil' do
                    it 'does not use the seed as a parameter name' do
                        described_class.any_instance.
                            stub(:valid_input_name_data?) { |name| name != seed }

                        mutable.mutations( seed ).
                            find { |m| m.inputs.keys.include? seed }.
                            should be_false
                    end
                end

                describe "#{Arachni::OptionGroups::Audit}#parameter_names" do
                    it 'serves as the default value of :parameter_names' do
                        Arachni::Options.audit.parameter_names = true
                        mutable.mutations( seed ).
                            find { |m| m.inputs.keys.include? seed }.
                            should be_true

                        Arachni::Options.audit.parameter_names = false
                        mutable.mutations( seed ).
                            find { |m| m.inputs.keys.include? seed }.
                            should be_false
                    end
                end
            end

            describe :skip do
                it 'skips mutation of parameters with these names' do
                    mutable.mutations( seed, skip: [ 'input_one' ] )
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
                mutable
                mutable.class.any_instance.stub(:valid_input_data?) { |i| i != '1' }

                mutable.mutations('1', skip_original: true ).size.should == 0
            end

            context 'as a value' do
                it 'skips the mutation' do
                    mutable.mutations(seed).
                        select { |m| m.affected_input_value.include? seed }.
                        size.should > 0

                    mutable.class.any_instance.
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
