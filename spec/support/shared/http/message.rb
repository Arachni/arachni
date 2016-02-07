shared_examples_for 'Arachni::HTTP::Message' do

    subject { described_class.new( url: url ) }
    let(:url) { 'http://test.com' }

    describe '#initialize' do
        it 'sets the instance attributes by the options' do
            options = {
                url:     url,
                headers: {
                    'X-Stuff' => 'Blah'
                }
            }

            r = described_class.new(options)
            expect(r.headers).to eq(options[:headers])
        end
    end

    describe '#scope' do
        it "returns #{described_class::Scope}" do
            expect(subject.scope).to be_kind_of described_class::Scope
        end
    end

    describe '#url=' do
        it 'sets the #url' do
            subject.url = "#{url}/2"
            expect(subject.url).to eq("#{url}/2")
        end

        it 'forces it to a string' do
            subject.url = nil
            expect(subject.url).to eq('')
        end

        it 'it freezes it' do
            url = 'HttP://Stuff.Com/'

            r = described_class.new( url: url )
            r.url = url
            expect(r.url).to be_frozen
        end

        context 'when :normalize_url is' do
            context 'not given' do
                it 'normalizes it' do
                    url = 'HttP://Stuff.Com/'
                    r = described_class.new( url: url )
                    r.url = url
                    expect(r.url).to eq(url.downcase)
                end
            end

            context 'nil' do
                it 'normalizes it' do
                    url = 'HttP://Stuff.Com/'
                    r = described_class.new( url: url, normalize_url: nil )
                    r.url = url
                    expect(r.url).to eq(url.downcase)
                end
            end

            context 'true' do
                it 'normalizes it' do
                    url = 'HttP://Stuff.Com/'
                    r = described_class.new( url: url, normalize_url: true )
                    r.url = url
                    expect(r.url).to eq(url.downcase)
                end
            end

            context 'false' do
                it 'does not normalize it' do
                    url = 'HttP://Stuff.Com/'
                    r = described_class.new( url: url, normalize_url: false )
                    r.url = url
                    expect(r.url).to eq(url)
                end
            end
        end
    end

    describe '#headers' do
        context 'when not configured' do
            it 'defaults to an empty Hash' do
                expect(subject.headers).to eq({})
            end
        end

        it 'returns the configured value' do
            headers = { 'Content-Type' => 'text/plain' }
            expect(described_class.new(url: url, headers: headers).headers).to eq(headers)
        end
    end

    describe '#body' do
        it 'returns the configured body' do
            body = 'Stuff...'
            expect(described_class.new(url: url, body: body).body).to eq(body)
        end
    end

end
