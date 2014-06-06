shared_examples_for 'Arachni::HTTP::Message' do

    subject { described_class.new( url: url ) }
    let(:url) { 'http://test.com' }

    describe '#to_rpc_data' do
        let(:data) { subject.scope; subject.to_rpc_data }

        %w(url body headers_string headers).each do |attribute|
            it "includes '#{attribute}'" do
                data[attribute].should == subject.send( attribute )
            end
        end

        it "does not include 'scope" do
            data.should_not include 'scope'
        end
    end

    describe '#initialize' do
        it 'sets the instance attributes by the options' do
            options = {
                url:     url,
                headers: {
                    'X-Stuff' => 'Blah'
                }
            }
            r = described_class.new(options)
            r.headers.should == options[:headers]
        end
    end

    describe '#scope' do
        it "returns #{described_class::Scope}" do
            subject.scope.should be_kind_of described_class::Scope
        end
    end

    describe '#url=' do
        it 'sets the #url' do
            subject.url = "#{url}/2"
            subject.url.should == "#{url}/2"
        end

        it 'forces it to a string' do
            subject.url = nil
            subject.url.should == ''
        end

        it 'it freezes it' do
            url = 'HttP://Stuff.Com/'

            r = described_class.new( url: url )
            r.url = url
            r.url.should be_frozen
        end

        it 'normalizes it' do
            url = 'HttP://Stuff.Com/'
            r = described_class.new( url: url )
            r.url = url
            r.url.should == url.downcase
        end
    end

    describe '#headers' do
        context 'when not configured' do
            it 'defaults to an empty Hash' do
                subject.headers.should == {}
            end
        end

        it 'returns the configured value' do
            headers = { 'Content-Type' => 'text/plain' }
            described_class.new(url: url, headers: headers).headers.should == headers
        end
    end

    describe '#body' do
        it 'returns the configured body' do
            body = 'Stuff...'
            described_class.new(url: url, body: body).body.should == body
        end
    end

end
