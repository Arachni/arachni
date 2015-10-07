shared_examples_for 'component_option' do

    let(:subject) do
        described_class.new( :option_name,
                             description: 'Description',
                             required:    true,
                             value:       'my value',
                             default:     'default value'
        )
    end

    it "supports #{Arachni::RPC::Serializer}" do
        expect(subject).to eq(Arachni::RPC::Serializer.deep_clone( subject ))
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        %w(name description default value type).each do |attribute|
            it "includes '#{attribute}'" do
                expect(data[attribute]).to eq(subject.send( attribute ))
            end
        end

        it "includes 'class'" do
            expect(data['class']).to eq(subject.class.to_s)
        end

        it "includes 'required'" do
            expect(data['required']).to eq(subject.required?)
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(name description default value type class).each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored.send( attribute )).to eq(subject.send( attribute ))
            end
        end

        it "restores 'required'" do
            expect(restored.required?).to eq(subject.required?)
        end
    end

    describe '#initialize' do
        context 'when passed invalid options' do
            it "raises #{ArgumentError}" do
                expect { described_class.new( :myname, stuff: 1 ) }.to raise_error ArgumentError
            end
        end
    end

    describe '#name' do
        it 'returns the name of the option' do
            name = 'myname'
            expect(described_class.new( name ).name).to eq(name.to_sym)
        end
    end

    describe '#description' do
        it 'returns the description' do
            description = 'a description'
            expect(described_class.new( '', description: description ).description).to eq(description)
        end
    end

    describe '#default' do
        it 'returns the default value' do
            default = 'default value'
            expect(described_class.new( '', default: default ).default).to eq(default)
        end
    end

    describe '#required?' do
        context 'when the option is mandatory' do
            it 'returns true' do
                expect(described_class.new( '', required: true ).required?).to be_truthy
            end
        end

        context 'when the option is not mandatory' do
            it 'returns false' do
                expect(described_class.new( '', required: false ).required?).to be_falsey
            end
        end

        context 'by default' do
            it 'returns false' do
                expect(described_class.new( '' ).required?).to be_falsey
            end
        end
    end

    describe '#missing_value?' do
        context 'when the option is required' do
            context 'and the value is not empty' do
                it 'returns false' do
                    expect(described_class.new( '', required: true, value: 'stuff' ).missing_value?).to be_falsey
                end
            end

            context 'and the value is nil' do
                it 'returns true' do
                    expect(described_class.new( '', required: true ).missing_value?).to be_truthy
                end
            end
        end

        context 'when the option is not required' do
            context 'and the value is not empty' do
                it 'returns false' do
                    expect(described_class.new( '', value: 'true' ).missing_value?).to be_falsey
                end
            end

            context 'and the value is empty' do
                it 'returns false' do
                    expect(described_class.new( '' ).missing_value?).to be_falsey
                end
            end
        end
    end

    describe '#value=' do
        it 'sets #value' do
            option = described_class.new( '' )
            option.value = 1
            expect(option.value).to eq(1)
        end
    end

    describe '#value' do
        it 'returns the set value' do
            option = described_class.new( '' )
            option.value = 1
            expect(option.value).to eq(1)
        end
    end

    describe '#effective_value' do
        it 'returns the set value' do
            option = described_class.new( '' )
            option.value = 1
            expect(option.value).to eq(1)
        end
    end

    describe '#effective_value' do
        it 'returns the value as is' do
            expect(described_class.new( '', value: 'blah' ).effective_value).to eq('blah')
        end

        context 'when no #value is set' do
            it 'returns #default' do
                expect(described_class.new( '', default: 'test' ).effective_value).to eq('test')
            end
        end
    end

    describe '#to_h' do
        let(:option) do
            described_class.new( :my_name,
                                 description: 'My description',
                                 required:    true,
                                 default:     'stuff'
            )
        end

        %w(name description value default type).each do |m|
            it "includes :#{m}" do
                expect(option.to_h[m.to_sym]).to eq(option.send(m))
            end
        end

        it 'includes :required' do
            expect(option.to_h[:required]).to eq(option.required?)
        end

        it 'is aliased to #to_hash' do
            expect(option.to_hash).to eq(option.to_h)
        end
    end
end
