require 'spec_helper'

describe Arachni::Element::JSON do
    it_should_behave_like 'element'

    it_should_behave_like 'with_source'
    it_should_behave_like 'with_auditor'

    it_should_behave_like 'submittable'
    it_should_behave_like 'inputtable'
    it_should_behave_like 'mutable'
    it_should_behave_like 'auditable'
    it_should_behave_like 'buffered_auditable'
    it_should_behave_like 'line_buffered_auditable'

    before :each do
        @framework ||= Arachni::Framework.new
        @auditor     = Auditor.new( Arachni::Page.from_url( url ), @framework )
    end

    after :each do
        @framework.reset
        reset_options
    end

    let(:auditor) { @auditor }

    def auditable_extract_parameters( resource )
        JSON.load( resource.body )
    end

    def run
        http.run
    end

    subject { described_class.new( url: "#{url}/submit", inputs: inputs, source: inputs.to_json ) }
    let(:inputs) { { 'input1' => 'value1' } }
    let(:url) { utilities.normalize_url( web_server_url_for( :json ) ) }
    let(:http) { Arachni::HTTP::Client }
    let(:utilities) { Arachni::Utilities }

    it 'is be assigned to Arachni::JSON for easy access' do
        expect(Arachni::JSON).to eq(described_class)
    end

    describe '#to_json' do
        let(:inputs) do
            {
                'stuff' => 'blah',
                'nested' => {
                    'nested-name'  => {
                        'deep-nested' => [
                            'item1',
                            'item2',
                            'item3'
                        ],
                        'deep-nested2' => [
                            '2item1',
                            '2item2',
                            '2item3'
                        ]
                    },
                    'nested-name2' => true
                }
            }
        end

        it 'returns the input data as JSON' do
            expect(subject.to_json).to eq(inputs.to_json)
        end
    end

    describe '#inputs=' do
        it 'sets inputs' do
            expect(subject.inputs).to eq(inputs)
        end

        it 'recursively converts keys to string' do
            subject.inputs = {
                stuff: 1,
                stuff2: {
                    stuff2: '2'
                }
            }

            expect(subject.inputs).to eq({
                'stuff'  => 1,
                'stuff2' => {
                    'stuff2' => '2'
                }
            })
        end

        context 'when it has nested hashes' do
            let(:inputs) do
                {
                    'stuff' => 'blah',
                    'nested' => {
                        'nested-name'  => 'nested-value',
                        'nested-name2' => true
                    }
                }
            end

            it 'preserves them' do
                expect(subject.inputs).to eq(inputs)
            end
        end

        context 'when it has nested arrays' do
            let(:inputs) do
                {
                    'stuff' => 'blah',
                    'nested' => [
                        'entry1',
                        true
                    ]
                }
            end

            it 'preserves them' do
                expect(subject.inputs).to eq(inputs)
            end
        end
    end

    describe '#affected_input_name=' do
        context 'when given an Array' do
            context 'with 1 item' do
                it 'stores the item as a String' do
                    affected_input_name = ['stuff']
                    subject.affected_input_name = affected_input_name
                    expect(subject.affected_input_name).to eq(affected_input_name.first)
                end
            end

            context 'with more than 1 items' do
                it 'sets the path to the fuzzed input' do
                    affected_input_name = ['stuff', 'stuff2']
                    subject.affected_input_name = affected_input_name
                    expect(subject.affected_input_name).to eq(affected_input_name)
                end
            end
        end
    end

    describe '#[]' do
        context 'when given an Array' do
            context 'pointing to a Hash location' do
                let(:inputs) do
                    {
                        'stuff' => 'blah',
                        'nested' => {
                            'nested-name'  => {
                                'deep-nested' => 'deep-value'
                            },
                            'nested-name2' => true
                        }
                    }
                end

                it 'returns the input data at that path' do
                    expect(subject[['nested', 'nested-name', 'deep-nested']]).to eq(
                        inputs['nested']['nested-name']['deep-nested']
                    )
                end
            end

            context 'pointing to an Array location' do
                let(:inputs) do
                    {
                        'stuff' => 'blah',
                        'nested' => {
                            'nested-name'  => {
                                'deep-nested' => [
                                    'item1',
                                    'item2',
                                    'item3'
                                ]
                            },
                            'nested-name2' => true
                        }
                    }
                end

                it 'returns the input data at that path' do
                    expect(subject[['nested', 'nested-name', 'deep-nested', 2]]).to eq(
                        inputs['nested']['nested-name']['deep-nested'][2]
                    )
                end
            end
        end
    end

    describe '#[]=' do
        context 'when given an Array' do
            context 'pointing to a Hash location' do
                let(:inputs) do
                    {
                        'stuff' => 'blah',
                        'nested' => {
                            'nested-name'  => {
                                'deep-nested' => 'deep-value'
                            },
                            'nested-name2' => true
                        }
                    }
                end

                it 'sets the input data at that path' do
                    subject[['nested', 'nested-name', 'deep-nested']] = 'foo'

                    expect(subject.inputs).to eq({
                        'stuff' => 'blah',
                        'nested' => {
                            'nested-name'  => {
                                'deep-nested' => 'foo'
                            },
                            'nested-name2' => true
                        }
                    })
                end
            end

            context 'pointing to an Array location' do
                let(:inputs) do
                    {
                        'stuff' => 'blah',
                        'nested' => {
                            'nested-name'  => {
                                'deep-nested' => [
                                    'item1',
                                    'item2',
                                    'item3'
                                ]
                            },
                            'nested-name2' => true
                        }
                    }
                end

                it 'returns the input data at that path' do
                    subject[['nested', 'nested-name', 'deep-nested', 1]] = 'foo'

                    expect(subject.inputs).to eq(
                        {
                            'stuff' => 'blah',
                            'nested' => {
                                'nested-name'  => {
                                    'deep-nested' => [
                                        'item1',
                                        'foo',
                                        'item3'
                                    ]
                                },
                                'nested-name2' => true
                            }
                        }
                    )
                end
            end
        end
    end

    describe '#update' do
        let(:inputs) do
            {
                'stuff' => 'blah',
                'nested' => {
                    'nested-name'  => {
                        'deep-nested' => [
                            'item1',
                            'item2',
                            'item3'
                        ],
                        'deep-nested2' => [
                            '2item1',
                            '2item2',
                            '2item3'
                        ]
                    },
                    'nested-name2' => true
                }
            }
        end

        it 'performs a deep update on the inputs' do
            subject.update({
                'stuff' => 'new stuff',
                'nested' => {
                    'nested-name' => {
                        'deep-nested' => [
                            'item1',
                            'new-item2',
                            'item3'
                        ]
                    }
                }
            })

            expect(subject.inputs).to eq({
                'stuff' => 'new stuff',
                'nested' => {
                    'nested-name'  => {
                        'deep-nested' => [
                            'item1',
                            'new-item2',
                            'item3'
                        ],
                        'deep-nested2' => [
                            '2item1',
                            '2item2',
                            '2item3'
                        ]
                    },
                    'nested-name2' => true
                }
            })
        end
    end

    describe '#mutations' do
        context 'when #inputs have nested' do
            context 'Hash' do
                let(:inputs) do
                    {
                        'stuff' => 'blah',
                        'nested' => {
                            'nested-name'  => {
                                'deep-nested' => 'deep blah'
                            },
                            'nested-name2' => true
                        }
                    }
                end

                it 'fuzzes its items' do
                    mutations = subject.mutations( 'seed',
                        format: [Arachni::Element::Capabilities::Mutable::Format::STRAIGHT]
                    )

                    mutations.each do |m|
                        expect(m[m.affected_input_name]).to eq('seed')
                        expect(m.affected_input_value).to eq('seed')
                    end

                    expect(mutations.map { |m| Hash[m.affected_input_name, m.inputs]}).to eq([
                        {
                            'stuff' => {
                                'stuff'  => 'seed',
                                'nested' => {
                                    'nested-name'  => {
                                        'deep-nested' => 'deep blah'
                                    },
                                    'nested-name2' => true
                                }
                            }
                        },
                        {
                            ['nested', 'nested-name', 'deep-nested'] => {
                                'stuff'  => 'blah',
                                'nested' => {
                                    'nested-name'  => {
                                        'deep-nested' => 'seed'
                                    },
                                    'nested-name2' => true
                                }
                            }
                        },
                        {
                            ['nested', 'nested-name2'] => {
                                'stuff'  => 'blah',
                                'nested' => {
                                    'nested-name'  => {
                                        'deep-nested' => 'deep blah'
                                    },
                                    'nested-name2' => 'seed'
                                }
                            }
                        }
                    ])
                end
            end

            context 'Array' do
                let(:inputs) do
                    {
                        'stuff' => 'blah',
                        'nested' => {
                            'nested-name'  => {
                                'deep-nested' => [
                                    'item1',
                                    'item2',
                                    'item3'
                                ]
                            },
                            'nested-name2' => true
                        }
                    }
                end

                it 'fuzzes its items' do
                    mutations = subject.mutations( 'seed',
                        format: [Arachni::Element::Capabilities::Mutable::Format::STRAIGHT]
                    )

                    mutations.each do |m|
                        expect(m[m.affected_input_name]).to eq('seed')
                        expect(m.affected_input_value).to eq('seed')
                    end

                    expect(mutations.map { |m| Hash[m.affected_input_name, m.inputs]}).to eq([
                        {
                            'stuff' => {
                                'stuff'  => 'seed',
                                'nested' => {
                                    'nested-name'  => {
                                        'deep-nested' => [
                                            'item1',
                                            'item2',
                                            'item3'
                                        ]
                                    },
                                    'nested-name2' => true
                                }
                            }
                        },
                        {
                            ['nested', 'nested-name', 'deep-nested', 0] => {
                                'stuff'  => 'blah',
                                'nested' => {
                                    'nested-name'  => {
                                        'deep-nested' => [
                                            'seed',
                                            'item2',
                                            'item3'
                                        ]
                                    },
                                    'nested-name2' => true
                                }
                            }
                        },
                        {
                            ['nested', 'nested-name', 'deep-nested', 1] => {
                                'stuff'  => 'blah',
                                'nested' => {
                                    'nested-name'  => {
                                        'deep-nested' => [
                                            'item1',
                                            'seed',
                                            'item3'
                                        ]
                                    },
                                    'nested-name2' => true
                                }
                            }
                        },
                        {
                            ['nested', 'nested-name', 'deep-nested', 2] => {
                                'stuff'  => 'blah',
                                'nested' => {
                                    'nested-name'  => {
                                        'deep-nested' => [
                                            'item1',
                                            'item2',
                                            'seed'
                                        ]
                                    },
                                    'nested-name2' => true
                                }
                            }
                        },
                        {
                            ['nested', 'nested-name2'] => {
                                'stuff'  => 'blah',
                                'nested' => {
                                    'nested-name'  => {
                                        'deep-nested' => [
                                            'item1',
                                            'item2',
                                            'item3'
                                        ]
                                    },
                                    'nested-name2' => 'seed'
                                }
                            }
                        }
                    ])
                end
            end
        end
    end

    describe '#simple' do
        it 'returns a simple Hash representation' do
            expect(subject.simple).to eq({ subject.action => subject.inputs })
        end
    end

    describe '#valid_input_data?' do
        it 'returns true' do
            expect(subject.valid_input_data?( 'stuff' )).to be_truthy
        end
    end

    describe '.encode' do
        it 'returns the string as is' do
            expect(described_class.encode( 'stuff' )).to eq('stuff')
        end
    end
    describe '#encode' do
        it 'returns the string as is' do
            expect(subject.encode( 'stuff' )).to eq('stuff')
        end
    end

    describe '.decode' do
        it 'returns the string as is' do
            expect(described_class.decode( 'stuff' )).to eq('stuff')
        end
    end
    describe '#decode' do
        it 'returns the string as is' do
            expect(subject.decode( 'stuff' )).to eq('stuff')
        end
    end

    describe '#type' do
        it 'is "json"' do
            expect(subject.type).to eq(:json)
        end
    end

    describe '.from_request' do
        it 'parses a request into an element'

        context 'when the body is empty' do
            it 'returns nil'
        end

        context 'when there are no inputs' do
            it 'returns nil'
        end

        context 'when it is' do
            context "equal to #{described_class::MAX_SIZE}" do
                let(:size) { described_class::MAX_SIZE }

                it 'returns nil'
            end

            context "larger than #{described_class::MAX_SIZE}" do
                let(:size) { described_class::MAX_SIZE + 1 }

                it 'returns nil'
            end

            context "smaller than #{described_class::MAX_SIZE}" do
                let(:size) { described_class::MAX_SIZE - 1 }

                it 'leaves parses it'
            end
        end
    end

end
