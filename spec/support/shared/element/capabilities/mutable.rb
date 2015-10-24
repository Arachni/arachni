shared_examples_for 'mutable' do |options = {}|

    before :each do
        begin
            Arachni::Options.audit.elements described_class.type
        rescue Arachni::OptionGroups::Audit::Error => e
        end
    end

    after :each do
        reset_options
    end

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
        expect(mutation).to eq(Arachni::RPC::Serializer.deep_clone( mutation ))
    end

    describe '#to_rpc_data' do
        let(:data) { mutation.to_rpc_data }

        %w(seed format affected_input_name).each do |attribute|
            it "includes '#{attribute}'" do
                expect(data[attribute]).to eq(mutation.send( attribute ))
            end
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { mutation.class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( mutation ) }

        %w(seed format affected_input_name).each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored.send( attribute )).to eq(mutation.send( attribute ))
            end
        end
    end

    describe '#mutation?' do
        context 'when the element has not been mutated' do
            it 'returns true' do
                expect(mutable.mutation?).to be_falsey
            end
        end
        context 'when the element has been mutated' do
            it 'returns false' do
                expect(mutable.mutations( seed ).first.mutation?).to be_truthy
            end
        end
    end

    describe '#with_raw_payload?' do
        let(:mutation) do
            mutable.mutations( seed ).first
        end

        context 'when #affected_input_name is in #raw_inputs' do
            it 'returns true' do
                mutation.raw_inputs << mutation.affected_input_name
                expect(mutation).to be_with_raw_payload
            end
        end

        context 'when #affected_input_name is not in #raw_inputs' do
            it 'returns true' do
                mutation.raw_inputs = []
                expect(mutation).to_not be_with_raw_payload
            end
        end
    end

    describe '#affected_input_value' do
        it 'returns the value of the affected_input_name input' do
            elem = mutable.mutations( seed ).first
            expect(elem.affected_input_value).to eq(seed)
        end

        context 'when no input has been affected_input_name' do
            it 'returns nil' do
                expect(mutable.affected_input_value).to be_nil
            end
        end
    end

    describe '#affected_input_value=' do
        it 'sets the value of the affected_input_name input' do
            elem = mutable.mutations( seed ).first
            elem.affected_input_value = 'stuff'
            expect(elem.affected_input_value).to eq('stuff')
            expect(elem.inputs.values.first).to eq('stuff')
        end
    end

    describe '#immutables' do
        it 'skips contained inputs' do
            input = mutable.inputs.keys.first

            mutable.immutables << input
            expect(mutable.mutations( seed ).
                reject { |e| e.affected_input_name != input }).
                to be_empty

            mutable.immutables.clear
            expect(mutable.mutations( seed ).
                reject { |e| e.affected_input_name != input }).
                to be_any
        end
    end

    describe '#mutations' do
        it 'mutates #inputs' do
            mutable.mutations( seed, skip_original: true ).each do |m|
                expect(mutable.url).to eq(m.url)
                expect(mutable.action).to eq(m.action)
                expect(mutable.inputs).not_to eq(m.inputs)
            end
        end

        it 'sets #affected_input_name to the name of the fuzzed input' do
            checked = false
            mutable.mutations( seed, skip_original: true ).each do |m|
                expect(mutable.url).to eq(m.url)
                expect(mutable.action).to eq(m.action)
                expect(mutable.affected_input_name).not_to eq(m.affected_input_name)
                expect(m.inputs[m.affected_input_name]).to include seed

                checked = true
            end

            expect(checked).to be_truthy
        end

        context 'with no options' do
            it 'returns all combinations' do
                expect(mutable.mutations( seed, skip_original: true ).size).to eq(
                    (inputs.size * 4) / (opts[:supports_nulls] ? 1 : 2)
                )
            end
        end

        context 'with option' do
            describe ':parameter_values' do
                describe 'true' do
                    it 'injects the payload into parameter values' do
                        expect(mutable.mutations( seed, parameter_values: true ).
                            find { |m| m.affected_input_value.include? seed }).
                            to be_truthy
                    end
                end
                describe 'false' do
                    it 'does not inject the payload into parameter values' do
                        expect(mutable.mutations( seed, parameter_values: false ).
                            find { |m| m.affected_input_value.include? seed }).
                            to be_falsey
                    end
                end
                describe 'nil' do
                    it 'injects the payload into parameter names' do
                        expect(mutable.mutations( seed ).
                            find { |m| m.affected_input_value.include? seed }).
                            to be_truthy
                    end
                end

                describe "#{Arachni::OptionGroups::Audit}#parameter_values" do
                    it 'serves as the default value of :parameter_values' do
                        Arachni::Options.audit.parameter_values = true
                        expect(mutable.mutations( seed ).
                            find { |m| m.affected_input_value.include? seed }).
                            to be_truthy

                        Arachni::Options.audit.parameter_values = false
                        expect(mutable.mutations( seed ).
                            find { |m| m.affected_input_value.include? seed }).
                            to be_falsey
                    end
                end
            end

            describe ':with_raw_payloads',
                     if: !described_class.ancestors.include?(
                         Arachni::Element::DOM
                     ) && described_class != Arachni::Element::JSON &&
                             described_class != Arachni::Element::XML &&
                             described_class != Arachni::Element::Header &&
                             described_class != Arachni::Element::Cookie do

                describe 'true' do
                    it 'adds an unencoded payload' do
                        expect(
                            mutable.mutations( seed, with_raw_payloads: true ).
                                find(&:with_raw_payload?)
                        ).to be_truthy
                    end
                end
                describe 'false' do
                    it 'does not add an unencoded payload' do
                        expect(mutable.mutations( seed, with_raw_payloads: false ).find do |m|
                            next if !m.audit_options[:submit]

                            m.audit_options[:submit][:raw_parameters] &&
                                m.audit_options[:submit][:raw_parameters].include?( m.affected_input_name )
                        end).to be_falsey
                    end
                end
                describe 'nil' do
                    it 'does not add an unencoded payload' do
                        expect(mutable.mutations( seed ).find do |m|
                            next if !m.audit_options[:submit]

                            m.audit_options[:submit][:raw_parameters] &&
                                m.audit_options[:submit][:raw_parameters].include?( m.affected_input_name )
                        end).to be_falsey
                    end
                end

                describe "#{Arachni::OptionGroups::Audit}#with_raw_payloads" do
                    it 'serves as the default value of :with_raw_payloads' do
                        Arachni::Options.audit.with_raw_payloads = true
                        expect(
                            mutable.mutations( seed ).find(&:with_raw_payload?)
                        ).to be_truthy

                        Arachni::Options.audit.with_raw_payloads = false
                        expect(
                            mutable.mutations( seed ).find(&:with_raw_payload?)
                        ).to be_falsey
                    end
                end
            end

            describe 'with_extra_parameter',
                     if: !described_class.ancestors.include?(
                         Arachni::Element::DOM
                     ) && described_class != Arachni::Element::LinkTemplate &&
                             described_class != Arachni::Element::XML do

                let(:extra_name) { described_class::EXTRA_NAME }

                describe 'true' do
                    it 'injects the payload into an extra parameter' do
                        expect(mutable.mutations( seed, with_extra_parameter: true ).
                            find { |m| m[extra_name].to_s.include? seed }).to be_truthy
                    end
                end
                describe 'false' do
                    it 'does not inject the payload into an extra parameter' do
                        expect(mutable.mutations( seed, with_extra_parameter: false ).
                            find { |m| m[extra_name].to_s.include? seed }).to be_falsey
                    end
                end
                describe 'nil' do
                    it 'does not inject the payload into an extra parameter' do
                        expect(mutable.mutations( seed ).
                            find { |m| m[extra_name].to_s.include? seed }).to be_falsey
                    end
                end

                describe "#{Arachni::OptionGroups::Audit}#with_extra_parameter" do
                    it 'serves as the default value of :with_extra_parameter' do
                        Arachni::Options.audit.with_extra_parameter = true
                        expect(mutable.mutations( seed ).
                            find { |m| m[extra_name].to_s.include? seed }).to be_truthy

                        Arachni::Options.audit.with_extra_parameter = false
                        expect(mutable.mutations( seed ).
                            find { |m| m[extra_name].to_s.include? seed }).to be_falsey
                    end
                end
            end

            describe 'with_both_http_methods',
                     if: !described_class.ancestors.include?(
                         Arachni::Element::DOM
                     ) && described_class != Arachni::Element::JSON &&
                             described_class != Arachni::Element::XML do

                describe 'false' do
                    it 'does not fuzz methods' do
                        expect(mutable.mutations( seed, with_both_http_methods: false ).
                            map(&:method).uniq).to eq [mutable.method]
                    end
                end
                describe 'true' do
                    it 'fuzzes methods' do
                        expect(mutable.mutations( seed, with_both_http_methods: true ).
                            map(&:method).uniq).to eq [:get, :post]
                    end
                end
                describe 'nil' do
                    it 'does not fuzz methods' do
                        expect(mutable.mutations( seed ).map(&:method).uniq).
                            to eq([mutable.method])
                    end
                end

                describe "#{Arachni::OptionGroups::Audit}#with_both_http_methods" do
                    it 'serves as the default value of :with_both_http_methods' do
                        Arachni::Options.audit.with_both_http_methods = true
                        expect(mutable.mutations( seed ).map(&:method).uniq).
                            to eq [:get, :post]

                        Arachni::Options.audit.with_both_http_methods = false
                        expect(mutable.mutations( seed ).map(&:method).uniq).
                            to eq([mutable.method])
                    end
                end
            end

            describe 'parameter_names',
                     if: !described_class.ancestors.include?( Arachni::Element::DOM) &&
                             described_class != Arachni::Element::LinkTemplate &&
                             described_class != Arachni::Element::XML do

                describe 'true' do
                    it 'uses the seed as a parameter name' do
                        expect(mutable.mutations( seed, parameter_names: true ).
                            find { |m| m.inputs.keys.include? seed }).
                            to be_truthy
                    end
                end
                describe 'false' do
                    it 'does not use the seed as a parameter name' do
                        allow_any_instance_of(mutable.class).
                            to receive(:valid_input_name_data?) { |instance, name| name != seed }

                        expect(mutable.mutations( seed, parameter_names: false ).
                            find { |m| m.inputs.keys.include? seed }).
                            to be_falsey
                    end
                end
                describe 'nil' do
                    it 'does not use the seed as a parameter name' do
                        allow_any_instance_of(described_class).
                            to receive(:valid_input_name_data?) { |instance, name| name != seed }

                        expect(mutable.mutations( seed ).
                            find { |m| m.inputs.keys.include? seed }).
                            to be_falsey
                    end
                end

                describe "#{Arachni::OptionGroups::Audit}#parameter_names" do
                    it 'serves as the default value of :parameter_names' do
                        Arachni::Options.audit.parameter_names = true
                        expect(mutable.mutations( seed ).
                            find { |m| m.inputs.keys.include? seed }).
                            to be_truthy

                        Arachni::Options.audit.parameter_names = false
                        expect(mutable.mutations( seed ).
                            find { |m| m.inputs.keys.include? seed }).
                            to be_falsey
                    end
                end
            end

            describe ':skip' do
                it 'skips mutation of parameters with these names' do
                    mutable.mutations( seed, skip: [ 'input_one' ] )
                end
            end

            describe ':format' do
                describe 'Format::STRAIGHT' do
                    it 'injects the seed as is' do
                        m = mutable.mutations( seed,
                                                format: [Arachni::Element::Capabilities::Mutable::Format::STRAIGHT],
                                                skip_original: true ).first
                        expect(m[m.affected_input_name]).to eq(seed)
                    end
                end
                describe 'Format::APPEND' do
                    it 'appends the seed to the current value' do
                        m = mutable.mutations( seed,
                                                format: [Arachni::Element::Capabilities::Mutable::Format::APPEND],
                                                skip_original: true ).first
                        expect(m[m.affected_input_name]).to eq(inputs[m.affected_input_name] + seed)
                    end
                end
                describe 'Format::NULL' do
                    it 'terminates the string with a null character',
                       if: described_class != Arachni::Element::Header &&
                               described_class.is_a?( Arachni::Element::DOM ) do

                        m = mutable.mutations( seed,
                                                format: [Arachni::Element::Capabilities::Mutable::Format::NULL],
                                                skip_original: true ).first
                        expect(m[m.affected_input_name]).to eq(seed + "\0")
                    end
                end
                describe 'Format::SEMICOLON' do
                    it 'prepends the seed with a semicolon' do
                        m = mutable.mutations( seed,
                                                format: [Arachni::Element::Capabilities::Mutable::Format::SEMICOLON],
                                                skip_original: true ).first
                        expect(m[m.affected_input_name]).to eq(';' + seed)
                    end
                end
                describe 'Format::APPEND | Format::NULL' do
                    it 'appends the seed and terminate the string with a null character',
                       if: described_class != Arachni::Element::Header &&
                            described_class.is_a?( Arachni::Element::DOM ) do

                        format = [Arachni::Element::Capabilities::Mutable::Format::APPEND |
                                      Arachni::Element::Capabilities::Mutable::Format::NULL]
                        m = mutable.mutations( seed, format: format, skip_original: true  ).first
                        expect(m[m.affected_input_name]).to eq(inputs[m.affected_input_name] + seed + "\0")
                    end
                end
            end
        end

        context 'when the payload is not supported' do
            it 'returns an empty array' do
                mutable
                allow_any_instance_of(mutable.class).to receive(:valid_input_data?) { |instance, i| i != '1' }

                expect(mutable.mutations('1', skip_original: true ).size).to eq(0)
            end

            context 'as a value' do
                it 'skips the mutation' do
                    expect(mutable.mutations(seed).
                        select { |m| m.affected_input_value.include? seed }.
                        size).to be > 0

                    allow_any_instance_of(mutable.class).
                        to receive(:valid_input_value_data?) { |instance, value| value.include? seed }

                    expect(mutable.mutations('1').
                        select { |m| m.affected_input_value.include? seed }.
                        size).to eq(0)
                end
            end
        end
    end

    describe '#affected_input_name' do
        it 'returns the name of the mutated input' do
            m = mutable.mutations( seed,
                                    format: [Arachni::Element::Capabilities::Mutable::Format::STRAIGHT],
                                    skip_original: true ).first
            expect(m.inputs[m.affected_input_name]).not_to eq(inputs[m.affected_input_name])
        end

        context 'when no input has been affected_input_name' do
            it 'returns nil' do
                expect(mutable.affected_input_name).to be_nil
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

            expect(seeds.sort.uniq).to eq(%w(my_seed))
        end
    end

    describe '#dup' do
        let(:dupped) { mutation.dup }

        it 'preserves #seed' do
            expect(dupped.seed).to eq(mutation.seed)
        end
        it 'preserves #affected_input_name' do
            expect(dupped.affected_input_name).to eq(mutation.affected_input_name)
        end
        it 'preserves #format' do
            expect(dupped.format).to eq(mutation.format)
        end
        it 'preserves #immutables' do
            mutation.immutables << 'stuff'
            expect(dupped.immutables).to eq(mutation.immutables)
        end
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            hash = mutation.to_h
            expect(hash[:affected_input_name]).to eq(mutation.affected_input_name)
            expect(hash[:affected_input_value]).to eq(mutation.affected_input_value)
            expect(hash[:seed]).to eq(mutation.seed)
        end

        context 'when the element is not a mutation' do
            it 'does not include mutation related data' do
                hash = mutable.to_h
                expect(hash).not_to include :affected_input_name
                expect(hash).not_to include :affected_input_value
                expect(hash).not_to include :seed
            end
        end
    end

end
