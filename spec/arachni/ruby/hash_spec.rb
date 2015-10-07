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

    describe '#my_stringify_keys' do
        it 'recursively converts keys to strings' do
            expect(with_symbols.my_stringify_keys).to eq(with_strings)
        end

        context 'when the recursive is set to false' do
            it 'only converts the keys at depth 1' do
                expect(with_symbols.my_stringify_keys( false )).to eq({
                    'stuff' => 'blah',
                    'more'  => {
                        stuff: {
                            blah: 'stuff'
                        }
                    }
                })
            end
        end
    end

    describe '#my_symbolize_keys' do
        it 'recursively converts keys to symbols' do
            expect(with_strings.my_symbolize_keys).to eq(with_symbols)
        end

        context 'when the recursive is set to false' do
            it 'only converts the keys at depth 1' do
                expect(with_strings.my_symbolize_keys( false )).to eq({
                    stuff: 'blah',
                    more:  {
                        'stuff' => {
                            'blah' => 'stuff'
                        }
                    }
                })
            end
        end
    end

    describe '#stringify_recursively_and_freeze' do
        it 'converts keys and values to frozen strings' do
            converted = with_symbols.stringify_recursively_and_freeze

            expect(converted).to eq(with_strings)
            expect(converted.keys.map(&:frozen?).uniq).to eq([true])
            expect(converted.values.map(&:frozen?).uniq).to eq([true])
        end

        it 'returns a frozen hash' do
            expect(with_symbols.stringify_recursively_and_freeze).to be_frozen
        end
    end

    describe '#my_stringify' do
        it 'returns a Hash with keys and values recursively converted to strings' do
            expect({
                test:         'blah',
                another_hash: {
                    stuff: 'test'
                }
            }.my_stringify).to eq({
                'test'         => 'blah',
                'another_hash' => {
                    'stuff' => 'test'
                }
            })
        end
    end

    describe '#recode' do
        it 'recursively converts String data to UTF8' do
            recoded = {
                blah: "\xE2\x9C\x93",
                blah2: {
                    blah3: "\xE2\x9C\x93"
                }
            }.recode
            expect(recoded[:blah]).to eq("\u2713")
            expect(recoded[:blah2][:blah3]).to eq("\u2713")
        end
    end

    describe '#downcase' do
        it 'converts keys and values to lower-case strings' do
            expect({ Stuff: 'VaLue', 'BlAh' => 'VaLUe 2' }.downcase).to eq(
                { 'stuff' => 'value', 'blah' => 'value 2' }
            )
        end
    end

    describe '#find_symbol_keys_recursively' do
        it 'returns all symbol keys from self and children hashes' do
            expect({
                stuff: 'VaLue',
                stuff2: {
                    stuff3: {
                        stuff4: 'Blah'
                    }
                }
            }.find_symbol_keys_recursively.sort).to eq(
                [:stuff, :stuff2, :stuff3, :stuff4].sort
            )
        end
    end
end
