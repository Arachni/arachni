require 'spec_helper'

describe Hash do
    let( :with_symbols ) do
        {
            stuff: 'blah',
            more: {
                stuff: {
                    blah: 'stuff'
                }
            }
        }
    end

    let( :with_strings ) do
        {
            'stuff' => 'blah',
            'more'  => {
                'stuff' => {
                    'blah' => 'stuff'
                }
            }
        }
    end

    describe '#stringify_keys' do
        it 'recursively converts keys to strings' do
            with_symbols.stringify_keys.should == with_strings
        end

        context 'when the recursive is set to false' do
            it 'only converts the keys at depth 1' do
                with_symbols.stringify_keys( false ).should == {
                    'stuff' => 'blah',
                    'more'  => {
                        stuff: {
                            blah: 'stuff'
                        }
                    }
                }
            end
        end
    end

    describe '#symbolize_keys' do
        it 'recursively converts keys to symbols' do
            with_strings.symbolize_keys.should ==with_symbols
        end

        context 'when the recursive is set to false' do
            it 'only converts the keys at depth 1' do
                with_strings.symbolize_keys( false ).should == {
                    stuff: 'blah',
                    more:  {
                        'stuff' => {
                            'blah' => 'stuff'
                        }
                    }
                }
            end
        end
    end

    describe '#stringify' do
        it 'returns a Hash with keys and values recursively converted to strings' do
            {
                test:         'blah',
                another_hash: {
                    stuff: 'test'
                }
            }.stringify.should == {
                'test'         => 'blah',
                'another_hash' => {
                    'stuff' => 'test'
                }
            }

        end
    end

    describe '#downcase' do
        it 'converts keys and values to lower-case strings' do
            { Stuff: 'VaLue', 'BlAh' => 'VaLUe 2' }.downcase.should ==
                { 'stuff' => 'value', 'blah' => 'value 2' }
        end
    end
end
