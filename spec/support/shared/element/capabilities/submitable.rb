shared_examples_for 'submitable' do

    let(:submitable) do
        s = subject.dup
        s.auditor = auditor
        s
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

    describe '#to_h' do
        it 'returns a hash representation of self' do
            hash = submitable.to_h
            hash[:url].should    == submitable.url
            hash[:action].should == submitable.action
            hash[:method].should == submitable.method
        end
    end
end
