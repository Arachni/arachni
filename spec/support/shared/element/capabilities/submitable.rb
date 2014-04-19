shared_examples_for 'submitable' do

    let(:submitable) do
        s = subject.dup
        s.auditor = auditor
        s
    end

    rpc_attributes = if described_class == Arachni::Element::Link::DOM
                         %w(url method)
                     else
                         %w(url action method)
                     end

    describe '#to_rpc_data' do
        let(:data) { submitable.to_rpc_data }

        rpc_attributes.each do |attribute|
            it "includes '#{attribute}'" do
                data[attribute].should == submitable.send( attribute )
            end
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { submitable.class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( submitable ) }

        rpc_attributes.each do |attribute|
            it "restores '#{attribute}'" do
                restored.send( attribute ).should == submitable.send( attribute )
            end
        end
    end

    describe '#platforms' do
        it 'returns platforms for the given element' do
            submitable.platforms.should be_kind_of Arachni::Platform::Manager
        end
    end

    describe '#submit' do
        it 'submits the element using its auditable inputs as params' do
            submitted = nil

            submitable.submit do |res|
                submitted = auditable_extract_parameters( res )
            end

            run
            submitable.inputs.should == submitted
        end

        it 'assigns the auditable element as the request performer' do
            response = nil
            submitable.submit { |res| response = res }

            run
            response.request.performer.should == submitable
        end
    end

    describe '#dup' do
        let(:dupped) { submitable.dup }

        it 'preserves #method' do
            dupped.method.should == submitable.method
        end
        it 'preserves #action' do
            dupped.action.should == submitable.action
        end
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            hash = submitable.to_h
            hash[:url].should    == submitable.url
            hash[:action].should == submitable.action
            hash[:method].should == submitable.method
        end
    end
end
