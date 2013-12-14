shared_examples_for 'mutable' do

    let(:inputs) { { 'another_param_name' => 'another_param_value' } }
    let(:seed) { 'my_seed' }
    let(:mutable) { described_class.new( url: 'http://test.com', inputs: inputs  ) }

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

    describe '#mutations' do
        it 'mutates #auditable' do
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
            it 'returns all combinatios' do
                # We set the skip_original option because it only applies to forms.
                mutable.mutations( seed, skip_original: true ).size.should == 4
            end
        end

        describe '#immutables' do
            it 'skips parameters contained parameters' do
                l = described_class.new(
                    url: 'http://test.com',
                    inputs: {
                        'input_one' => 'value 1',
                        'input_two' => 'value 2'
                    }
                )
                l.immutables << 'input_one'
                l.mutations( seed ).reject { |e| e.affected_input_name != 'input_one' }
                .should be_empty

                l.immutables.clear
                l.mutations( seed ).reject { |e| e.affected_input_name != 'input_one' }
                .should be_any
            end
        end

        context 'with option' do
            describe :respect_method do
                describe true do
                    it 'does not fuzz methods' do
                        e = described_class.new(
                            url: 'http://test.com',
                            inputs: {
                                'input_one' => 'value 1',
                                'input_two' => 'value 2'
                            }
                        )

                        respect_method = e.mutations( seed, respect_method: true )
                        respect_method.size.should == 9

                        respect_method.map{ |m| m.method }.uniq.should == [e.method]
                    end
                end
                describe false do
                    it 'fuzzes methods' do
                        e = described_class.new(
                            url: 'http://test.com',
                            inputs: {
                                'input_one' => 'value 1',
                                'input_two' => 'value 2'
                            }
                        )

                        no_respect_method = e.mutations( seed, respect_method: false )
                        no_respect_method.size.should == 17

                        no_respect_method.map{ |m| m.method }.uniq.size.should == 2
                    end
                    it 'generates mutations with POST' do
                        m = mutable.mutations( 'stuff', respect_method: false )
                        m.size.should == 9

                        m.select { |f| f.method.to_s.downcase == 'post' }.size.should == 4
                    end

                    it 'generates mutations with GET' do
                        m = mutable.mutations( 'stuff', respect_method: false )
                        m.size.should == 9

                        m.select { |f| f.method.to_s.downcase == 'get' }.size.should ==
                            m.select { |f| f.method.to_s.downcase == 'post' }.size + 1
                    end
                end
                describe 'nil' do
                    it 'does not fuzz methods' do
                        e = described_class.new(
                            url: 'http://test.com',
                            inputs: {
                                'input_one' => 'value 1',
                                'input_two' => 'value 2'
                            }
                        )

                        respect_method = e.mutations( seed )
                        respect_method.size.should == 9

                        respect_method.map{ |m| m.method }.uniq.should == [e.method]
                    end
                end
            end
            describe 'Options.fuzz_methods' do
                it 'serves as the default value of :respect_method' do
                    e = described_class.new(
                        url: 'http://test.com',
                        inputs: {
                            'input_one' => 'value 1',
                            'input_two' => 'value 2'
                        }
                    )

                    Arachni::Options.fuzz_methods = true
                    no_respect_method = e.mutations( seed )
                    no_respect_method.size.should == 17

                    no_respect_method.map{ |m| m.method }.uniq.size.should == 2

                    Arachni::Options.fuzz_methods = false
                    respect_method = e.mutations( seed )
                    respect_method.size.should == 9

                    respect_method.map{ |m| m.method }.uniq.should == [e.method]

                end
            end

            describe :skip do
                it 'skips mutation of parameters with these names' do
                    described_class.new(
                        url: 'http://test.com',
                        inputs: {
                            'input_one' => 'value 1',
                            'input_two' => 'value 2'
                        }
                    ).mutations( seed, skip: [ 'input_one' ] )
                end
            end
            describe :param_flip do
                it 'uses the seed as a param name' do
                    m = mutable.mutations( seed,
                                            format: [Arachni::Element::Capabilities::Mutable::Format::STRAIGHT],
                                            param_flip:    true,
                                            skip_original: true ).last
                    m.inputs[seed].should be_true
                end
            end
            describe :format do
                describe 'Format::STRAIGHT' do
                    it 'injects the seed as is' do
                        m = mutable.mutations( seed,
                                                format: [Arachni::Element::Capabilities::Mutable::Format::STRAIGHT],
                                                skip_original: true ).first
                        m.inputs[m.affected_input_name].should == seed
                    end
                end
                describe 'Format::APPEND' do
                    it 'appends the seed to the current value' do
                        m = mutable.mutations( seed,
                                                format: [Arachni::Element::Capabilities::Mutable::Format::APPEND],
                                                skip_original: true ).first
                        m.inputs[m.affected_input_name].should == inputs[m.affected_input_name] + seed
                    end
                end
                describe 'Format::NULL' do
                    it 'terminates the string with a null character' do
                        m = mutable.mutations( seed,
                                                format: [Arachni::Element::Capabilities::Mutable::Format::NULL],
                                                skip_original: true ).first
                        m.inputs[m.affected_input_name].should == seed + "\0"
                    end
                end
                describe 'Format::SEMICOLON' do
                    it 'prepends the seed with a semicolon' do
                        m = mutable.mutations( seed,
                                                format: [Arachni::Element::Capabilities::Mutable::Format::SEMICOLON],
                                                skip_original: true ).first
                        m.inputs[m.affected_input_name].should == ';' + seed
                    end
                end
                describe 'Format::APPEND | Format::NULL' do
                    it 'appends the seed and terminate the string with a null character' do
                        format = [Arachni::Element::Capabilities::Mutable::Format::APPEND |
                                      Arachni::Element::Capabilities::Mutable::Format::NULL]
                        m = mutable.mutations( seed, format: format, skip_original: true  ).first
                        m.inputs[m.affected_input_name].should == inputs[m.affected_input_name] + seed + "\0"
                    end
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
            values.sort.should == %W(another_param_valuemy_seed
                another_param_valuemy_seed\x00 my_seed my_seed\x00).sort
        end
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            hash = mutable.mutations( seed ).first.to_h
            %w(affected_input_name affected_input_value seed).
                map { |k| hash[k.to_sym] }.should ==
                    %w(another_param_name my_seed my_seed)
        end

        context 'when the element is not a mutation' do
            it 'does not include mutation related data' do
                hash = mutable.to_h
                %w(affected_input_name affected_input_value seed).
                    each { |k| hash.should_not include k.to_sym }
            end
        end
    end

end
