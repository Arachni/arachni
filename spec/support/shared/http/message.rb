shared_examples_for 'Arachni::HTTP::Message' do

    let(:url) { 'http://test.com' }

    describe '#initialize' do
        it 'sets the instance attributes by the options' do
            options = {
                url:     url,
                version: '1.0',
                headers: {
                    'X-Stuff' => 'Blah'
                }
            }
            r = described_class.new(options)
            r.version.should == options[:version]
            r.headers.should == options[:headers]
        end
    end

    describe '#version' do
        it 'defaults to 1.1' do
            described_class.new(url: url).version.should == '1.1'
        end
    end

    describe '#headers' do
        context 'when not configured' do
            it 'defaults to an empty Hash' do
                described_class.new(url: url).headers.should == {}
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
