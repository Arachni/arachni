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
                expect(data[attribute]).to eq(submittable.send( attribute ))
            end
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { submittable.class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( submittable ) }

        rpc_attributes.each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored.send( attribute )).to eq(submittable.send( attribute ))
            end
        end
    end

    describe '#method' do
        it 'returns the HTTP method' do
            submittable.method = :stuff
            expect(submittable.method).to eq(:stuff)
        end
    end

    describe '#http_method' do
        it 'is aliased to #method' do
            submittable.method = :stuff
            expect(submittable.http_method).to eq(:stuff)
        end
    end

    describe '#method=' do
        it 'returns the HTTP method' do
            submittable.method = :stuff
            expect(submittable.http_method).to eq(:stuff)
        end
    end

    describe '#http_method=' do
        it 'is aliased to #method=' do
            submittable.http_method = :stuff
            expect(submittable.method).to eq(:stuff)
        end
    end

    describe '#platforms' do
        it 'returns platforms for the given element' do
            expect(submittable.platforms).to be_kind_of Arachni::Platform::Manager
        end
    end

    describe '#submit' do
        it 'submits the element using its auditable inputs as params' do
            submitted = nil

            submittable.submit do |res|
                submitted = auditable_extract_parameters( res )
            end

            run
            expect(submittable.inputs).to eq(submitted)
        end

        it 'assigns the auditable element as the request performer' do
            response = nil
            submittable.submit { |res| response = res }

            run
            expect(response.request.performer).to eq(submittable)
        end

        it 'sets Request#raw_parameters from #raw_inputs',
           if: !described_class.ancestors.include?( Arachni::Element::DOM ) do

            response = nil

            submittable.raw_inputs = [submittable.inputs.keys.first]
            submittable.submit { |res| response = res }

            run
            expect(response.request.raw_parameters).to eq([submittable.inputs.keys.first])
        end
    end

    describe '#id' do
        before do
            allow_any_instance_of(described_class).to receive(:valid_input_name?) { true }
            allow_any_instance_of(described_class).to receive(:valid_input_value?) { true }
        end

        let(:action) { "#{url}/action" }

        it 'uniquely identifies the element based on #action' do
            e = submittable.dup
            allow(e).to receive(:action) { action }

            c = submittable.dup
            allow(c).to receive(:action) { "#{action}2" }

            expect(e.id).not_to eq(c.id)
        end

        it 'uniquely identifies the element based on #method' do
            e = submittable.dup
            allow(e).to receive(:method) { :get }

            c = submittable.dup
            allow(c).to receive(:method) { :post }

            expect(e.id).not_to eq(c.id)
        end

        it 'uniquely identifies the element based on #type' do
            e = submittable.dup
            allow(e).to receive(:type) { :stuff }

            c = submittable.dup
            allow(c).to receive(:type) { :stoof }

            expect(e.id).not_to eq(c.id)
        end

        it 'uniquely identifies the element based on #inputs' do
            e = submittable.dup
            e.inputs = { input1: 'stuff' }

            c = submittable.dup
            c.inputs = { input1: 'stuff2' }

            expect(e.id).not_to eq(c.id)
        end
    end

    describe '#dup' do
        let(:dupped) { submittable.dup }

        it 'preserves #method' do
            expect(dupped.method).to eq(submittable.method)
        end
        it 'preserves #action' do
            expect(dupped.action).to eq(submittable.action)
        end
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            hash = submittable.to_h
            expect(hash[:url]).to    eq(submittable.url)
            expect(hash[:action]).to eq(submittable.action)
            expect(hash[:method]).to eq(submittable.method)
        end
    end
end
