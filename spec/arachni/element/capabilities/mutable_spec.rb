require 'spec_helper'

describe Arachni::Element::Capabilities::Mutable do
    before( :all ) do
        @inputs = { 'another_param_name' => 'another_param_value' }
        @seed = 'my_seed'
        @mutable = Arachni::Element::Link.new( url: 'http://test.com', inputs: @inputs  )
    end

    describe '#original?' do
        context 'when the element has not been mutated' do
            it 'returns true' do
                e = Arachni::Element::Link.new(url:  'http://test.com', inputs: @inputs )
                e.original?.should be_true
            end
        end
        context 'when the element has been mutated' do
            it 'returns false' do
                e = Arachni::Element::Link.new( url: 'http://test.com', inputs: @inputs )
                e.mutations( @seed ).first.original?.should be_false
            end
        end
    end

    describe '#mutated?' do
        context 'when the element has not been mutated' do
            it 'returns true' do
                e = Arachni::Element::Link.new( url: 'http://test.com', inputs: @inputs )
                e.mutated?.should be_false
            end
        end
        context 'when the element has been mutated' do
            it 'returns false' do
                e = Arachni::Element::Link.new( url: 'http://test.com', inputs: @inputs )
                e.mutations( @seed ).first.mutated?.should be_true
            end
        end
    end

    describe '#altered_value' do
        it 'returns the value of the altered input' do
            e = Arachni::Element::Link.new( url: 'http://test.com', inputs: @inputs )
            elem = e.mutations_for( @seed ).first
            elem.altered_value.should == @seed
        end
    end

    describe '#altered_value=' do
        it 'sets the value of the altered input' do
            e = Arachni::Element::Link.new( url: 'http://test.com', inputs: @inputs )
            elem = e.mutations_for( @seed ).first
            elem.altered_value = 'stuff'
            elem.altered_value.should == 'stuff'
            elem.inputs.values.first.should == 'stuff'
        end
    end

    describe '#mutations' do
        it 'aliased to #mutations_for' do
            e = Arachni::Element::Link.new( url: 'http://test.com', inputs: @inputs )
            e.mutations_for( @seed ).should == e.mutations( @seed )
        end
        it 'aliased to #permutations' do
            e = Arachni::Element::Link.new( url: 'http://test.com', inputs: @inputs )
            e.permutations( @seed ).should == e.mutations( @seed )
        end
        it 'aliased to #permutations_for' do
            e = Arachni::Element::Link.new( url: 'http://test.com', inputs: @inputs )
            e.permutations_for( @seed ).should == e.mutations( @seed )
        end

        it 'mutates #auditable' do
            e = Arachni::Element::Link.new( url: 'http://test.com', inputs: @inputs )
            e.mutations( @seed ).each do |m|
                e.url.should == m.url
                e.action.should == m.action
                e.inputs.should_not == m.inputs
            end
        end

        it 'sets #altered to the name of the fuzzed input' do
            e = Arachni::Element::Link.new( url: 'http://test.com', inputs: @inputs )

            checked = false
            e.mutations( @seed ).each do |m|
                e.url.should == m.url
                e.action.should == m.action
                e.altered.should_not == m.altered
                m.inputs[m.altered].should include @seed

                checked = true
            end

            checked.should be_true
        end

        context 'with no options' do
            it 'returns all combinatios' do
                inputs = {
                    'param_name' => 'param_value',
                    'email' => nil
                }
                Arachni::Element::Link.new( url: 'http://test.com', inputs: inputs )
                    .mutations( @seed ).size.should == 8
            end
        end

        describe '#immutables' do
            it 'skips parameters contained parameters' do
                l = Arachni::Element::Link.new(
                    url: 'http://test.com',
                    inputs: {
                        'input_one' => 'value 1',
                        'input_two' => 'value 2'
                    }
                )
                l.immutables << 'input_one'
                l.mutations( @seed ).reject { |e| e.altered != 'input_one' }
                    .should be_empty

                l.immutables.clear
                l.mutations( @seed ).reject { |e| e.altered != 'input_one' }
                    .should be_any
            end
        end

        context 'with option' do
            describe :respect_method do
                describe true do
                    it 'does not fuzz methods' do
                        e = Arachni::Element::Form.new(
                            url: 'http://test.com',
                            inputs: {
                                        'input_one' => 'value 1',
                                        'input_two' => 'value 2'
                                    }
                        )

                        respect_method = e.mutations( @seed, respect_method: true )
                        respect_method.size.should == 9

                        respect_method.map{ |m| m.method }.uniq.should == [e.method]
                    end
                end
                describe false do
                    it 'fuzzes methods' do
                        e = Arachni::Element::Form.new(
                            url: 'http://test.com',
                            inputs: {
                                        'input_one' => 'value 1',
                                        'input_two' => 'value 2'
                                    }
                        )

                        no_respect_method = e.mutations( @seed, respect_method: false )
                        no_respect_method.size.should == 17

                        no_respect_method.map{ |m| m.method }.uniq.size.should == 2
                    end
                    it 'generates mutations with POST' do
                        inputs = { 'param_name' => 'param_value' }
                        e = Arachni::Element::Form.new( url: 'http://test.com', inputs: inputs )
                        m = e.mutations( 'stuff', respect_method: false )
                        m.size.should == 9

                        m.select { |f| f.method.to_s.downcase == 'post' }.size.should == 4
                    end

                    it 'generates mutations with GET' do
                        inputs = { 'param_name' => 'param_value' }
                        e = Arachni::Element::Form.new( url: 'http://test.com', inputs: inputs )
                        m = e.mutations( 'stuff', respect_method: false )
                        m.size.should == 9

                        m.select { |f| f.method.to_s.downcase == 'get' }.size.should ==
                            m.select { |f| f.method.to_s.downcase == 'post' }.size + 1
                    end
                end
                describe 'nil' do
                    it 'does not fuzz methods' do
                        e = Arachni::Element::Form.new(
                            url: 'http://test.com',
                            inputs: {
                                        'input_one' => 'value 1',
                                        'input_two' => 'value 2'
                                    }
                        )

                        respect_method = e.mutations( @seed )
                        respect_method.size.should == 9

                        respect_method.map{ |m| m.method }.uniq.should == [e.method]
                    end
                end
            end
            describe 'Options.fuzz_methods' do
                it 'serves as the default value of :respect_method' do
                    e = Arachni::Element::Form.new(
                        url: 'http://test.com',
                        inputs: {
                                    'input_one' => 'value 1',
                                    'input_two' => 'value 2'
                                }
                    )

                    Arachni::Options.fuzz_methods = true
                    no_respect_method = e.mutations( @seed )
                    no_respect_method.size.should == 17

                    no_respect_method.map{ |m| m.method }.uniq.size.should == 2

                    Arachni::Options.fuzz_methods = false
                    respect_method = e.mutations( @seed )
                    respect_method.size.should == 9

                    respect_method.map{ |m| m.method }.uniq.should == [e.method]

                end
            end

            describe :skip do
                it 'skips mutation of parameters with these names' do
                    Arachni::Element::Form.new(
                        url: 'http://test.com',
                        inputs: {
                            'input_one' => 'value 1',
                            'input_two' => 'value 2'
                        }
                    ).mutations( @seed, skip: [ 'input_one' ] )
                end
            end
            describe :param_flip do
                it 'uses the seed as a param name' do
                    m = @mutable.mutations( @seed,
                        format: [Arachni::Element::Capabilities::Mutable::Format::STRAIGHT],
                        param_flip: true ).last
                    m.inputs[@seed].should be_true
                end
            end
            describe :format do
                describe 'Format::STRAIGHT' do
                    it 'injects the seed as is' do
                        m = @mutable.mutations( @seed,
                            format: [Arachni::Element::Capabilities::Mutable::Format::STRAIGHT] ).first
                        m.inputs[m.altered].should == @seed
                    end
                end
                describe 'Format::APPEND' do
                    it 'appends the seed to the current value' do
                        m = @mutable.mutations( @seed,
                            format: [Arachni::Element::Capabilities::Mutable::Format::APPEND] ).first
                        m.inputs[m.altered].should == @inputs[m.altered] + @seed
                    end
                end
                describe 'Format::NULL' do
                    it 'terminates the string with a null character' do
                        m = @mutable.mutations( @seed,
                            format: [Arachni::Element::Capabilities::Mutable::Format::NULL] ).first
                        m.inputs[m.altered].should == @seed + "\0"
                    end
                end
                describe 'Format::SEMICOLON' do
                    it 'prepends the seed with a semicolon' do
                        m = @mutable.mutations( @seed,
                            format: [Arachni::Element::Capabilities::Mutable::Format::SEMICOLON] ).first
                        m.inputs[m.altered].should == ';' + @seed
                    end
                end
                describe 'Format::APPEND | Format::NULL' do
                    it 'appends the seed and terminate the string with a null character' do
                        format = [Arachni::Element::Capabilities::Mutable::Format::APPEND |
                                     Arachni::Element::Capabilities::Mutable::Format::NULL]
                        m = @mutable.mutations( @seed, format: format ).first
                        m.inputs[m.altered].should == @inputs[m.altered] + @seed + "\0"
                    end
                end
            end
        end
    end

    describe '#altered' do
        it 'returns the name of the mutated input' do
            m = @mutable.mutations( @seed,
                format: [Arachni::Element::Capabilities::Mutable::Format::STRAIGHT] ).first
            m.inputs[m.altered].should_not == @inputs[m.altered]
        end
    end

end
