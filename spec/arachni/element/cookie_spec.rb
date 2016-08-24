require 'spec_helper'

describe Arachni::Element::Cookie do
    it_should_behave_like 'element'

    it_should_behave_like 'with_source'
    it_should_behave_like 'with_dom'
    it_should_behave_like 'with_auditor'

    it_should_behave_like 'submittable'
    it_should_behave_like 'inputtable', single_input: true
    it_should_behave_like 'mutable',    single_input: true
    it_should_behave_like 'auditable'
    it_should_behave_like 'buffered_auditable'
    it_should_behave_like 'line_buffered_auditable'

    before :each do
        @framework ||= Arachni::Framework.new
        @auditor     = Auditor.new( Arachni::Page.from_url( url ), @framework )
    end

    after :each do
        @framework.reset
        reset_options
    end

    let(:auditor) { @auditor }

    def auditable_extract_parameters( resource )
        YAML.load( resource.body )
    end

    def run
        http.run
    end

    let(:url) { utilities.normalize_url( web_server_url_for( :cookie ) ) }
    let(:http) { Arachni::HTTP::Client }
    let(:utilities) { Arachni::Utilities }
    let(:inputs) do
        { 'mycookie' => 'myvalue' }
    end
    subject do
        described_class.new(
            url:     "#{url}submit",
            name:    inputs.keys.first,
            value:   inputs.values.first,
            expires: Time.now + 99999999999
        )
    end

    it 'should be assigned to Arachni::Cookie for easy access' do
        expect(Arachni::Cookie).to eq(described_class)
    end

    context 'when initialized' do
        context 'with hash key/pair' do
            describe '#simple' do
                it 'returns name/val as a key/pair' do
                    expect(subject.simple).to eq(inputs)
                end
            end
        end

        context 'domain' do
            context 'specified' do
                subject do
                    described_class.new(
                        url:     "#{url}submit",
                        name:    inputs.keys.first,
                        value:   inputs.values.first,
                        expires: Time.now + 99999999999,
                        domain:  '.localhost'
                    )
                end

                it 'sets it to the given value' do
                    expect(subject.domain).to eq '.localhost'
                end
            end

            context 'missing' do
                subject do
                    described_class.new(
                        url:     "#{url}submit",
                        name:    inputs.keys.first,
                        value:   inputs.values.first,
                        expires: Time.now + 99999999999
                    )
                end

                it 'sets it to the URL host' do
                    expect(subject.domain).to eq Arachni::URI(url).host
                end
            end
        end
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "converts initialization_options['expires'] to String" do
            expect(data['initialization_options']['expires']).to eq(subject.expires_at.to_s)
        end

        it "converts data['expires'] to String" do
            expect(data['data']['expires']).to eq(subject.expires_at.to_s)
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        it "restores initialization_options['expires']" do
            expect(subject.expires_at).to be_kind_of Time
            expect(restored.expires_at.to_s).to eq(subject.expires_at.to_s)
        end
    end

    describe '#mutations' do
        describe ':parameter_names' do
            it 'creates a new cookie' do
                expect(subject.mutations( 'seed', parameter_names: true ).last.inputs.keys).to eq(
                    %w(seed)
                )
            end
        end
        describe 'Options.audit.cookies_extensively' do
            it 'submits the default elements of the page along with the cookie mutations' do
                p = Arachni::Page.from_url( url + 'with_other_elements' )
                a = Auditor.new
                a.page = p
                c = p.cookies.first
                c.auditor = a


                expect(c.mutations( 'seed' ).map { |e| e.type }.uniq.size).to eq(1)

                mutations = c.mutations( 'seed' ).map { |e| e.inputs }

                Arachni::Options.audit.cookies_extensively = true
                expect(c.mutations( 'seed' ).map { |e| e.type }.uniq.size).to be > 1
                c.mutations( 'seed' ).each do |e|
                    next if e.is_a? described_class

                    expect(mutations).to include e.audit_options[:submit][:cookies]
                end

                Arachni::Options.audit.cookies_extensively = false
                expect(c.mutations( 'seed' ).map { |e| e.type }.uniq.size).to eq(1)
            end
        end
    end

    describe '#type' do
        it 'is "cookie"' do
            expect(subject.type).to eq(:cookie)
        end
    end

    describe '#secure?' do
        context 'when set' do
            it 'returns true' do
                expect(described_class.new(
                    url:    url,
                    name:  'mycookie',
                    value: 'myvalue',
                    secure: true
                ).secure?).to be_truthy
            end
        end

        context 'when not set' do
            it 'returns false' do
                expect(subject.secure?).to be_falsey
            end
        end
    end

    describe '#httponly?' do
        context 'when set' do
            it 'returns true' do
                expect(described_class.new(
                    url:      url,
                    name:     'mycookie',
                    value:    'myvalue',
                    httponly: true
                ).http_only?).to be_truthy
            end
        end

        context 'when not set' do
            it 'returns false' do
                expect(subject.http_only?).to be_falsey
            end
        end
    end

    describe '#session?' do
        context 'when cookie is session cookie' do
            it 'returns true' do
                expect(described_class.new(
                    url:      url,
                    name:     'mycookie',
                    value:    'myvalue',
                    httponly: true
                ).session?).to be_truthy
            end
        end

        context 'when cookie is not session cookie' do
            it 'returns false' do
                expect(described_class.new(
                    url:     url,
                    name:    'mycookie',
                    value:   'myvalue',
                    expires: Time.now
                ).session?).to be_falsey
            end
        end
    end

    describe '#expired?' do
        context 'when expiry date is set' do
            context 'and has expired' do
                it 'returns true' do
                    described_class.new(
                        url:     url,
                        name:    '',
                        value:   '',
                        expires: Time.at( 0 )
                    ).expired?
                end
            end

            context 'and has not expired' do
                it 'returns false' do
                    expect(described_class.new(
                        url:     url,
                        name:    '',
                        value:   '',
                        expires: Time.now + 999999
                    ).expired?).to be_falsey
                end
            end
        end

        context 'when not set' do
            it 'returns false' do
                expect(subject.http_only?).to be_falsey
            end
        end
    end

    describe '#data' do
        it 'returns the cookie data' do
            expect(subject.data).to eq({
                name:        'mycookie',
                value:       'myvalue',
                raw_name:    nil,
                raw_value:   nil,
                url:         subject.action,
                expires:     subject.expires_at,
                version:     0,
                port:        nil,
                discard:     nil,
                comment_url: nil,
                max_age:     nil,
                comment:     nil,
                secure:      nil,
                path:        '/submit',
                domain:      Arachni::URI(url).host,
                httponly:    false
            })
        end
    end

    describe '#dom' do
        context 'when there are no #inputs' do
            it 'returns nil' do
                subject.inputs = {}
                expect(subject.dom).to be_nil
            end
        end
    end

    describe '#name' do
        it 'returns the name of the cookie' do
            expect(subject.name).to eq('mycookie')
        end
    end

    describe '#value' do
        it 'returns the value of the cookie' do
            expect(subject.value).to eq('myvalue')
        end
    end

    describe '.encode' do

        it 'encodes the string in a way that makes is suitable to be included in a cookie header' do
            expect(described_class.encode( 'some stuff \'";%=&' )).to eq('some+stuff+\'%22%3B%25%3D%26')
        end

        %w(! ' / : ).each do |character|
            it "preserves '#{character}'" do
                expect(described_class.encode( character )).to eq(character)
            end
        end

        ['+', ';', '%', "\0", '&', '"', "\n", "\r", '='].each do |character|
            it "encodes '#{character}'" do
                expect(described_class.encode( character )).to eq("%#{character.unpack('H*')[0]}".upcase)
            end

            it "encodes space as '+'" do
                expect(described_class.encode( ' ' )).to eq('+')
            end
        end
    end

    describe '.decode' do
        it 'delegates to Form.decode' do
            string = 'some stuff'

            allow(Arachni::Form).to receive(:decode) { 'ret' }.with( string )
            expect(described_class.decode( string )).to eq('ret')
        end
    end

    describe '#to_set_cookie' do
        context 'when the cookie is for all subdomains' do
            it 'includes a Domain attribute' do
                c = described_class.new(
                    url:    url,
                    name:   'blah=ha%',
                    value:  'some stuff ;',
                    path:   '/stuff',
                    domain: '.localhost'
                )

                expect(described_class.from_set_cookie( url, c.to_set_cookie ).first).to eq(c)
                expect(c.to_set_cookie).to eq(
                    'blah%3Dha%25=some+stuff+%3B; Path=/stuff; Domain=.localhost'
                )
            end
        end

        context 'when the cookie is for a single domain' do
            it 'does not include a Domain attribute' do
                c = described_class.new(
                    url:      url,
                    name:     'blah=ha%',
                    value:    'some stuff ;',
                    secure:   true,
                    httponly: true,
                    domain:   'localhost'
                )

                expect(c.to_set_cookie).to eq(
                    'blah%3Dha%25=some+stuff+%3B; Path=/; Secure; HttpOnly'
                )
                expect(described_class.from_set_cookie( url, c.to_set_cookie ).first).to eq(c)
            end
        end
    end

    describe '#to_s' do
        context 'when there are no raw data' do
            it 'returns the encoded name/value pair' do
                c = described_class.new(
                    url:    url,
                    name:  'blah=ha%',
                    value: 'some stuff ;',
                )
                expect(c.to_s).to eq('blah%3Dha%25=some+stuff+%3B')
            end
        end

        context 'when there are raw data' do
            context 'and has not been updated' do
                it 'returns them' do
                    c = described_class.new(
                        url:    url,
                        name:  'blah=ha%',
                        value: 'some stuff ;',
                        raw_name: 'blah',
                        raw_value: 'blah2'
                    )
                    expect(c.to_s).to eq('blah=blah2')
                end
            end

            context 'and has been updated' do
                it 'returns the encoded name/value pair' do
                    c = described_class.new(
                        url:    url,
                        name:  'blah=ha%',
                        value: 'some stuff ;',
                        raw_name: 'blah',
                        raw_value: 'blah2'
                    )
                    expect(c).to receive(:updated?) { true }
                    expect(c.to_s).to eq('blah%3Dha%25=some+stuff+%3B')
                end
            end
        end
    end

    describe '#auditable=' do
        it 'properly encodes the value before storing it' do
            c = described_class.new(
                url:   url,
                name:  'blah',
                value: 'some stuff ;',
            )

            expect(c.inputs.values.first).to eq('some stuff ;')
        end
    end

    describe '.from_file' do
        it 'parses a Netscape cookie_jar file into an array of cookies' do
            cookies =  described_class.from_file( url, fixtures_path + 'cookies.txt' )
            expect(cookies.size).to eq(4)

            cookie = cookies.shift
            expect(cookie.action).to eq(url)
            expect(cookie.url).to eq(url)
            expect(cookie.inputs).to eq({ 'first_name' => 'first_value' })
            expect(cookie.simple).to eq({ 'first_name' => 'first_value' })
            expect(cookie.domain).to eq('.domain.com')
            expect(cookie.path).to eq('/path/to/somewhere')
            expect(cookie.secure).to eq(true)
            expect(cookie.session?).to eq(false)
            expect(cookie.expires.is_a?( Time )).to eq(true)
            expect(cookie.name).to eq('first_name')
            expect(cookie.value).to eq('first_value')

            cookie = cookies.shift
            expect(cookie.action).to eq(url)
            expect(cookie.url).to eq(url)
            expect(cookie.inputs).to eq({ 'second_name' => 'second_value' })
            expect(cookie.simple).to eq({ 'second_name' => 'second_value' })
            expect(cookie.domain).to eq('another-domain.com')
            expect(cookie.path).to eq('/')
            expect(cookie.secure).to eq(false)
            expect(cookie.session?).to eq(true)
            expect(cookie.expires).to be_nil
            expect(cookie.name).to eq('second_name')
            expect(cookie.value).to eq('second_value')

            cookie = cookies.shift
            expect(cookie.action).to eq(url)
            expect(cookie.url).to eq(url)
            expect(cookie.inputs).to eq({ 'coo@ki e2' => 'blah val2@' })
            expect(cookie.simple).to eq({ 'coo@ki e2' => 'blah val2@' })
            expect(cookie.domain).to eq('.blah-domain')
            expect(cookie.path).to eq('/')
            expect(cookie.secure).to eq(false)
            expect(cookie.session?).to eq(false)
            expect(cookie.expires).to eq(Time.parse( '2020-08-09 16:59:20 +0300' ))
            expect(cookie.name).to eq('coo@ki e2')
            expect(cookie.raw_name).to eq('coo%40ki+e2')
            expect(cookie.value).to eq('blah val2@')
            expect(cookie.raw_value).to eq('blah+val2%40')

            cookie = cookies.shift
            expect(cookie.action).to eq(url)
            expect(cookie.url).to eq(url)
            expect(cookie.inputs).to eq({ '_superapp_session' => 'MzE4OjEzNzU0Mzc0OTc4NDI6MmY3YzkxMTkwZDE5MTRmNjBlYjY4OGQ5ZjczMTU1ZTQzNGM2Y2IwNA==' })
            expect(cookie.simple).to eq({ '_superapp_session' => 'MzE4OjEzNzU0Mzc0OTc4NDI6MmY3YzkxMTkwZDE5MTRmNjBlYjY4OGQ5ZjczMTU1ZTQzNGM2Y2IwNA==' })
            expect(cookie.domain).to eq('192.168.1.1')
            expect(cookie.path).to eq('/')
            expect(cookie.secure).to eq(false)
            expect(cookie.session?).to eq(true)
            expect(cookie.expires).to be_nil
            expect(cookie.name).to eq('_superapp_session')
            expect(cookie.raw_name).to eq('_superapp_session')
            expect(cookie.value).to eq('MzE4OjEzNzU0Mzc0OTc4NDI6MmY3YzkxMTkwZDE5MTRmNjBlYjY4OGQ5ZjczMTU1ZTQzNGM2Y2IwNA==')
            expect(cookie.raw_value).to eq('MzE4OjEzNzU0Mzc0OTc4NDI6MmY3YzkxMTkwZDE5MTRmNjBlYjY4OGQ5ZjczMTU1ZTQzNGM2Y2IwNA%3D%3D')
        end
    end

    describe '.from_response' do
        context 'when the response contains cookies' do
            it 'returns an array of cookies' do
                response = http.get( url + '/set_cookie', mode: :sync )
                cookies = described_class.from_response( response )
                expect(cookies.size).to eq(1)
                cookie = cookies.first
                expect(cookie.name).to eq('my-cookie')
                expect(cookie.value).to eq('my-val')
            end
        end
    end

    describe '.from_parser' do
        let(:parser) do
            Arachni::Parser.new(
                Arachni::HTTP::Response.new(
                    url:  url,
                    body: html,
                    headers: {
                        'Content-Type' => 'text/html'
                    })
            )
        end

        context 'when there are any set-cookie attributes in http-equiv' do
            let(:html) do
                <<-EOHTML
                    <html>
                    <head>
                        <meta http-equiv="Set-Cookie" content="cookie=val+1; httponly">
                        <meta http-equiv="Set-Cookie" content="cookie2+1=val2; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Path=/; Domain=.foo.com; HttpOnly; secure">
                    </head>
                    </html>
                EOHTML
            end

            it 'returns an array of cookies' do
                cookies = described_class.from_parser( parser )
                expect(cookies.size).to eq(2)

                cookie = cookies.shift
                expect(cookie.name).to eq('cookie')
                expect(cookie.value).to eq('val 1')
                expect(cookie.raw_name).to eq('cookie')
                expect(cookie.raw_value).to eq('val+1')
                expect(cookie.expired?).to eq(false)
                expect(cookie.session?).to eq(true)
                expect(cookie.secure?).to eq(false)

                cookie = cookies.shift
                expect(cookie.name).to eq('cookie2 1')
                expect(cookie.value).to eq('val2')
                expect(cookie.raw_name).to eq('cookie2+1')
                expect(cookie.raw_value).to eq('val2')
                expect(cookie.path).to eq('/')
                expect(cookie.domain).to eq('.foo.com')
                expect(cookie.secure?).to eq(true)
                expect(cookie.expired?).to eq(true)
            end

            context 'with an empty string' do
                let(:html) do
                    ''
                end

                it 'returns an empty array' do
                     expect(described_class.from_parser( parser )).to be_empty
                end
            end
        end
    end

    describe '.from_headers' do
        context 'when there are any set-cookie attributes in http-equiv' do
            context 'with a String document' do
                it 'returns an array of cookies' do
                    headers = {
                        'set-cookie' => "coo%40ki+e2=blah+val2%40; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Path=/; Domain=.foo.com; HttpOnly"
                    }

                    cookies = described_class.from_headers( 'http://test.com', headers )
                    expect(cookies.size).to eq(1)
                    expect(cookies.first.name).to eq('coo@ki e2')
                    expect(cookies.first.value).to eq('blah val2@')
                    expect(cookies.first.raw_name).to eq('coo%40ki+e2')
                    expect(cookies.first.raw_value).to eq('blah+val2%40')
                end
            end
            context 'with an empty string' do
                it 'returns an empty array' do
                     expect(described_class.from_headers( '', {} )).to be_empty
                end
            end
        end
    end

    describe '.from_set_cookie' do
        it 'parses the contents of the Set-Cookie header field into cookies' do
            sc = "SomeCookie=MzE4OjEzNzU0Mzc0OTc4NDI6MmY3YzkxMTkwZDE5MTRmNjBlYjY4OGQ5ZjczMTU1ZTQzNGM2Y2IwNA%3D%3D"
            c1 = described_class.from_set_cookie( 'http://test.com', sc ).first

            expect(c1).to eq(described_class.from_set_cookie( 'http://test.com', sc ).first)

            sc2 = "SomeCookie=\"MzE4OjEzNzU0Mzc0OTc4NDI6MmY3YzkxMTkwZDE5MTRmNjBlYjY4OGQ5ZjczMTU1ZTQzNGM2Y2IwNA==\""
            c2 = described_class.from_set_cookie( 'http://test.com', sc2 ).first

            expect(c1).to eq(c2)
            expect(c1.name).to eq('SomeCookie')
            expect(c1.value).to eq('MzE4OjEzNzU0Mzc0OTc4NDI6MmY3YzkxMTkwZDE5MTRmNjBlYjY4OGQ5ZjczMTU1ZTQzNGM2Y2IwNA==')

            expect(c1.raw_name).to eq('SomeCookie')
            expect(c1.raw_value).to eq('MzE4OjEzNzU0Mzc0OTc4NDI6MmY3YzkxMTkwZDE5MTRmNjBlYjY4OGQ5ZjczMTU1ZTQzNGM2Y2IwNA%3D%3D')

            expect(c2.raw_name).to eq('SomeCookie')
            expect(c2.raw_value).to eq('"MzE4OjEzNzU0Mzc0OTc4NDI6MmY3YzkxMTkwZDE5MTRmNjBlYjY4OGQ5ZjczMTU1ZTQzNGM2Y2IwNA=="')

            sc3 = "coo%40ki+e2=blah+val2%40; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Path=/stuff; Domain=.foo.com; HttpOnly"
            cookies = described_class.from_set_cookie( 'http://test.com', sc3 )
            expect(cookies.size).to eq(1)
            cookie = cookies.first
            expect(cookie.name).to eq('coo@ki e2')
            expect(cookie.value).to eq('blah val2@')
            expect(cookie.raw_name).to eq('coo%40ki+e2')
            expect(cookie.raw_value).to eq('blah+val2%40')
            expect(cookie.path).to eq('/stuff')
            expect(cookie.source).to eq(sc3)
        end

        it 'can handle v1 values' do
            cookie = described_class.from_set_cookie(
                'http://owner-url.com',
                'cookie="blah stuff"'
            ).first

            expect(cookie.value).to eq('blah stuff')
            expect(cookie.raw_value).to eq('"blah stuff"')
        end

        context 'when there is no path' do
            it "'reverts to '/'" do
                sc3 = "coo%40ki+e2=blah+val2%40; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Domain=.foo.com; HttpOnly"
                cookies = described_class.from_set_cookie( 'http://test.com/stuff', sc3 )
                expect(cookies.size).to eq(1)
                cookie = cookies.first
                expect(cookie.name).to eq('coo@ki e2')
                expect(cookie.value).to eq('blah val2@')
                expect(cookie.raw_name).to eq('coo%40ki+e2')
                expect(cookie.raw_value).to eq('blah+val2%40')
                expect(cookie.path).to eq('/')
            end
        end

        context 'when there is a domain' do
            context 'and it starts with a dot' do
                it 'uses it verbatim' do
                    sc = 'coo%40ki+e2=blah+val2%40; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Domain=.test.com; HttpOnly'
                    cookie = described_class.from_set_cookie( 'http://test.com/stuff', sc ).first
                    expect(cookie.domain).to eq '.test.com'
                end
            end

            context 'and it does not start with a dot' do
                it 'prefixes it with a dot' do
                    sc = 'coo%40ki+e2=blah+val2%40; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Domain=test.com; HttpOnly'
                    cookie = described_class.from_set_cookie( 'http://test.com/stuff', sc ).first
                    expect(cookie.domain).to eq '.test.com'
                end
            end

            context 'and it is an IP address' do
                it 'uses it verbatim' do
                    sc = 'coo%40ki+e2=blah+val2%40; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Domain=127.0.0.2; HttpOnly'
                    cookie = described_class.from_set_cookie( 'http://test.com/stuff', sc ).first
                    expect(cookie.domain).to eq '127.0.0.2'
                end
            end
        end

        context 'when there is no domain' do
            it 'uses it URL host' do
                sc = 'coo%40ki+e2=blah+val2%40; Expires=Thu, 01 Jan 1970 00:00:01 GMT; HttpOnly'
                cookie = described_class.from_set_cookie( 'http://test.com/stuff', sc ).first
                expect(cookie.domain).to eq 'test.com'
            end
        end

        context 'when its value is' do
            let(:value) { 'a' * size }
            let(:cookie) { "cookie=#{value}; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Domain=.foo.com; HttpOnly" }

            context "equal to #{described_class::MAX_SIZE}" do
                let(:size) { described_class::MAX_SIZE }

                it 'returns empty array' do
                    expect(described_class.from_set_cookie(
                        'http://test.com/stuff',
                        cookie
                    ).first.value).to be_empty
                end
            end

            context "larger than #{described_class::MAX_SIZE}" do
                let(:size) { described_class::MAX_SIZE + 1 }

                it 'sets empty value' do
                    expect(described_class.from_set_cookie(
                        'http://test.com/stuff',
                        cookie
                    ).first.value).to be_empty
                end
            end

            context "smaller than #{described_class::MAX_SIZE}" do
                let(:size) { described_class::MAX_SIZE - 1 }

                it 'leaves the values alone' do
                    expect(described_class.from_set_cookie(
                        'http://test.com/stuff',
                        cookie
                    ).first.value).to eq(value)
                end
            end
        end
    end

    describe '.from_string' do
        it 'parses cookies formatted as a string' do
             cookies = described_class.from_string( 'http://owner-url.com',
                "coo%40ki+e2=blah+val2%40;name=value;name2=value2")
             expect(cookies.size).to eq(3)

             c = cookies.shift
             expect(c.name).to eq('coo@ki e2')
             expect(c.value).to eq('blah val2@')
             expect(c.raw_name).to eq('coo%40ki+e2')
             expect(c.raw_value).to eq('blah+val2%40')

             c = cookies.shift
             expect(c.name).to eq('name')
             expect(c.value).to eq('value')
             expect(c.raw_name).to eq('name')
             expect(c.raw_value).to eq('value')

             c = cookies.shift
             expect(c.name).to eq('name2')
             expect(c.value).to eq('value2')
             expect(c.raw_name).to eq('name2')
             expect(c.raw_value).to eq('value2')
        end

        it 'can handle v1 values' do
            cookie = described_class.from_string(
                'http://owner-url.com',
                'cookie="blah stuff"'
            ).first

            expect(cookie.value).to eq('blah stuff')
            expect(cookie.raw_value).to eq('"blah stuff"')
        end

        context 'when its value is' do
            let(:value) { 'a' * size }
            let(:cookie) { "cookie=#{value}" }

            context "equal to #{described_class::MAX_SIZE}" do
                let(:size) { described_class::MAX_SIZE }

                it 'sets empty value' do
                    expect(described_class.from_string(
                        'http://owner-url.com',
                        cookie
                    ).first.value).to be_empty
                end
            end

            context "larger than #{described_class::MAX_SIZE}" do
                let(:size) { described_class::MAX_SIZE + 1 }

                it 'sets empty value' do
                    expect(described_class.from_string(
                        'http://owner-url.com',
                        cookie
                    ).first.value).to be_empty
                end
            end

            context "smaller than #{described_class::MAX_SIZE}" do
                let(:size) { described_class::MAX_SIZE - 1 }

                it 'leaves the values alone' do
                    expect(described_class.from_string(
                        'http://owner-url.com',
                        cookie
                    ).first.value).to eq(value)
                end
            end
        end
    end

end
