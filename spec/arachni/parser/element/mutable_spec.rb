require_relative '../../../spec_helper'

describe Arachni::Parser::Element::Mutable do
    before( :all ) do
        @inputs = { 'another_param_name' => 'another_param_value' }
        @seed = 'my_seed'
        @mutable = Arachni::Parser::Element::Link.new( 'http://test.com', inputs: @inputs  )
    end

    describe :mutations do
        context 'with no options' do
            it 'should return all combinatios' do
                inputs = { inputs:
                    {
                        'param_name' => 'param_value',
                        'email' => nil
                    }
                }
                Arachni::Parser::Element::Form.new( 'http://test.com', inputs )
                    .mutations( @seed ).size.should == 10
            end
        end

        describe :immutables do
            it 'should skip parameters which is contains' do
                l = Arachni::Parser::Element::Link.new( 'http://test.com',
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
            describe :skip do
                it 'should skip mutation of parameters with these names' do
                    Arachni::Parser::Element::Form.new( 'http://test.com',
                        inputs: {
                            'input_one' => 'value 1',
                            'input_two' => 'value 2'
                        }
                    ).mutations( @seed, skip: [ 'input_one' ] )
                end
            end
            describe :skip_orig do
                it 'should skip adding a mutation with original and default values' do
                    Arachni::Parser::Element::Form.new( 'http://test.com', inputs: @inputs )
                    .mutations( @seed, skip_orig: true )
                    .size.should == 4
                end
            end
            describe :param_flip do
                it 'should use the seed as a param name' do
                    m = @mutable.mutations( @seed,
                        format: [Arachni::Parser::Element::Mutable::Format::STRAIGHT],
                        param_flip: true ).last
                    m.auditable[@seed].should be_true
                end
            end
            describe :format do
                describe 'Format::STRAIGHT' do
                    it 'should inject the seed as is' do
                        m = @mutable.mutations( @seed,
                            format: [Arachni::Parser::Element::Mutable::Format::STRAIGHT] ).first
                        m.auditable[m.altered].should == @seed
                    end
                end
                describe 'Format::APPEND' do
                    it 'should append the seed to the current value' do
                        m = @mutable.mutations( @seed,
                            format: [Arachni::Parser::Element::Mutable::Format::APPEND] ).first
                        m.auditable[m.altered].should == @inputs[m.altered] + @seed
                    end
                end
                describe 'Format::NULL' do
                    it 'should terminate the string with a null character' do
                        m = @mutable.mutations( @seed,
                            format: [Arachni::Parser::Element::Mutable::Format::NULL] ).first
                        m.auditable[m.altered].should == @seed + "\0"
                    end
                end
                describe 'Format::SEMICOLON' do
                    it 'should prepend the seed with a semicolon' do
                        m = @mutable.mutations( @seed,
                            format: [Arachni::Parser::Element::Mutable::Format::SEMICOLON] ).first
                        m.auditable[m.altered].should == ';' + @seed
                    end
                end
                describe 'Format::APPEND | Format::NULL' do
                    it 'should append the seed and terminate the string with a null character' do
                        m = @mutable.mutations( @seed,
                            format: [Arachni::Parser::Element::Mutable::Format::APPEND | Arachni::Parser::Element::Mutable::Format::NULL] ).first
                        m.auditable[m.altered].should == @inputs[m.altered] + @seed + "\0"
                    end
                end
            end
        end
    end

    describe :altered do
        it 'should return the name of the mutated input' do
            m = @mutable.mutations( @seed,
                format: [Arachni::Parser::Element::Mutable::Format::STRAIGHT] ).first
            m.auditable[m.altered].should_not == @inputs[m.altered]
        end
    end

end
