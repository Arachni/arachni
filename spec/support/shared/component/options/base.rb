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
        subject.should == Arachni::RPC::Serializer.deep_clone( subject )
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        %w(name description default value type).each do |attribute|
            it "includes '#{attribute}'" do
                data[attribute].should == subject.send( attribute )
            end
        end

        it "includes 'class'" do
            data['class'].should == subject.class.to_s
        end

        it "includes 'required'" do
            data['required'].should == subject.required?
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(name description default value type class).each do |attribute|
            it "restores '#{attribute}'" do
                restored.send( attribute ).should == subject.send( attribute )
            end
        end

        it "restores 'required'" do
            restored.required?.should == subject.required?
        end
    end

    describe '#name' do
        it 'returns the name of the option' do
            name = 'myname'
            described_class.new( name ).name.should == name.to_sym
        end
    end

    describe '#description' do
        it 'returns the description' do
            description = 'a description'
            described_class.new( '', description: description ).description.should == description
        end
    end

    describe '#default' do
        it 'returns the default value' do
            default = 'default value'
            described_class.new( '', default: default ).default.should == default
        end
    end

    describe '#required?' do
        context 'when the option is mandatory' do
            it 'returns true' do
                described_class.new( '', required: true ).required?.should be_true
            end
        end

        context 'when the option is not mandatory' do
            it 'returns false' do
                described_class.new( '', required: false ).required?.should be_false
            end
        end

        context 'by default' do
            it 'returns false' do
                described_class.new( '' ).required?.should be_false
            end
        end
    end

    describe '#missing_value?' do
        context 'when the option is required' do
            context 'and the value is not empty' do
                it 'returns false' do
                    described_class.new( '', required: true, value: 'stuff' ).missing_value?.should be_false
                end
            end

            context 'and the value is nil' do
                it 'returns true' do
                    described_class.new( '', required: true ).missing_value?.should be_true
                end
            end
        end

        context 'when the option is not required' do
            context 'and the value is not empty' do
                it 'returns false' do
                    described_class.new( '', value: 'true' ).missing_value?.should be_false
                end
            end

            context 'and the value is empty' do
                it 'returns false' do
                    described_class.new( '' ).missing_value?.should be_false
                end
            end
        end
    end

    describe '#value=' do
        it 'sets #value' do
            option = described_class.new( '' )
            option.value = 1
            option.value.should == 1
        end
    end

    describe '#value' do
        it 'returns the set value' do
            option = described_class.new( '' )
            option.value = 1
            option.value.should == 1
        end
    end

    describe '#effective_value' do
        it 'returns the set value' do
            option = described_class.new( '' )
            option.value = 1
            option.value.should == 1
        end
    end

    describe '#effective_value' do
        it 'returns the value as is' do
            described_class.new( '', value: 'blah' ).effective_value.should == 'blah'
        end

        context 'when no #value is set' do
            it 'returns #default' do
                described_class.new( '', default: 'test' ).effective_value.should == 'test'
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
                option.to_h[m.to_sym].should == option.send(m)
            end
        end

        it 'includes :required' do
            option.to_h[:required].should == option.required?
        end

        it 'is aliased to #to_hash' do
            option.to_hash.should == option.to_h
        end
    end
end
