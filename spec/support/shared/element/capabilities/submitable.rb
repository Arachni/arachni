shared_examples_for 'submittable' do

    let(:submittable) do
        s = subject.dup
        s.auditor = auditor
        s
    end

    rpc_attributes = if [Arachni::Element::Link::DOM,
                         Arachni::Element::LinkTemplate::DOM].include? described_class
                         %w(url method)
                     else
                         %w(url action method)
                     end

    describe '#to_rpc_data' do
        let(:data) { submittable.to_rpc_data }

        rpc_attributes.each do |attribute|
            it "includes '#{attribute}'" do
                data[attribute].should == submittable.send( attribute )
            end
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { submittable.class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( submittable ) }

        rpc_attributes.each do |attribute|
            it "restores '#{attribute}'" do
                restored.send( attribute ).should == submittable.send( attribute )
            end
        end
    end

    describe '#platforms' do
        it 'returns platforms for the given element' do
            submittable.platforms.should be_kind_of Arachni::Platform::Manager
        end
    end

    describe '#submit' do
        it 'submits the element using its auditable inputs as params' do
            submitted = nil

            submittable.submit do |res|
                submitted = auditable_extract_parameters( res )
            end

            run
            submittable.inputs.should == submitted
        end

        it 'assigns the auditable element as the request performer' do
            response = nil
            submittable.submit { |res| response = res }

            run
            response.request.performer.should == submittable
        end
    end

    describe '#dup' do
        let(:dupped) { submittable.dup }

        it 'preserves #method' do
            dupped.method.should == submittable.method
        end
        it 'preserves #action' do
            dupped.action.should == submittable.action
        end
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            hash = submittable.to_h
            hash[:url].should    == submittable.url
            hash[:action].should == submittable.action
            hash[:method].should == submittable.method
        end
    end
end
