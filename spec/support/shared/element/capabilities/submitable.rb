shared_examples_for 'submitable' do

    def load( yaml )
        YAML.load( yaml )
    end

    describe '#platforms' do
        it 'returns platforms for the given element' do
            subject.platforms.should be_kind_of Arachni::Platform::Manager
        end
    end

    describe '#submit' do
        it 'submits the element using its auditable inputs as params' do
            submitted = nil

            subject.submit do |res|
                submitted = load( res.body )
            end

            auditor.http.run
            subject.inputs.should == submitted
        end

        it 'assigns the auditable element as the request performer' do
            response = nil
            subject.submit { |res| response = res }

            auditor.http.run
            response.request.performer.should == subject
        end
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            hash = subject.to_h
            hash[:url].should    == subject.url
            hash[:action].should == subject.action
            hash[:method].should == subject.method
        end
    end
end
