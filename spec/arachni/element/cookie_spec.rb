require 'spec_helper'

describe Arachni::Element::Cookie do
    it_should_behave_like 'auditable', url: web_server_url_for( :cookie ), single_input: true

    before( :all ) do
        @url = web_server_url_for( :cookie ) + '/'
        @raw = { 'mycookie' => 'myvalue' }
        @c = Arachni::Element::Cookie.new( url: @url, inputs: @raw )
        @http = Arachni::HTTP::Client.instance
    end

    it 'should be assigned to Arachni::Cookie for easy access' do
        Arachni::Cookie.should == Arachni::Element::Cookie
    end

    describe 'Arachni::Element::COOKIE' do
        it 'returns "cookie"' do
            Arachni::Element::COOKIE.should == 'cookie'
        end
    end

    context 'when initialized' do
        context 'with hash key/pair' do
            describe '#simple' do
                it 'returns name/val as a key/pair' do
                    c = Arachni::Element::Cookie.new(
                        url: @url,
                        inputs: { 'name' => 'val' }
                    )
                    c.simple.should == { 'name' => 'val' }
                end
            end
        end
        context 'with attributes' do
            describe '#simple' do
                it 'returns name/val as a key/pair' do
                    c = Arachni::Element::Cookie.new(
                        url:   @url,
                        name:  'myname',
                        value: 'myvalue'
                    )
                    c.simple.should == { 'myname' => 'myvalue' }
                end
            end
        end
    end

    describe '#dup' do
        it 'preserves its action URL' do
            url = 'http://stuff.net'
            c = Arachni::Element::Cookie.new(
                url: url,
                inputs: { 'name' => 'myname', 'value' => 'myvalue' }
            )
            c.action = url + '2'
            d = c.dup
            d.action.should == url + '2/'
            d.should == c
        end
    end

    describe '#mutations' do
        describe :param_flip do
            it 'creates a new cookie' do
                @c.mutations( 'seed', param_flip: true ).last.inputs.keys.should ==
                    %w(seed)
            end
        end
        describe 'Options.audit_cookies_extensively' do
            it 'submits the default elements of the page along with the cookie mutations' do
                p = Arachni::Page.from_url( @url + 'with_other_elements' )
                a = Auditor.new
                a.page = p
                c = p.cookies.first
                c.auditor = a


                c.mutations_for( 'seed' ).map { |e| e.type }.uniq.size.should == 1

                Arachni::Options.audit_cookies_extensively = true
                c.mutations_for( 'seed' ).map { |e| e.type }.uniq.size.should > 1

                Arachni::Options.audit_cookies_extensively = false
                c.mutations_for( 'seed' ).map { |e| e.type }.uniq.size.should == 1
            end
        end
    end

    describe '#type' do
        it 'is "cookie"' do
            @c.type.should == 'cookie'
        end
    end

    describe '#secure?' do
        context 'when set' do
            it 'returns true' do
                Arachni::Element::Cookie.new(
                    url:    @url,
                    name:  'mycookie',
                    value: 'myvalue',
                    secure: true
                ).secure?.should be_true
            end
        end

        context 'when not set' do
            it 'returns false' do
                @c.secure?.should be_false
            end
        end
    end

    describe '#httponly?' do
        context 'when set' do
            it 'returns true' do
                Arachni::Element::Cookie.new(
                    url:      @url,
                    name:     'mycookie',
                    value:    'myvalue',
                    httponly: true
                ).http_only?.should be_true
            end
        end

        context 'when not set' do
            it 'returns false' do
                @c.http_only?.should be_false
            end
        end
    end

    describe '#session?' do
        context 'when cookie is session cookie' do
            it 'returns true' do
                Arachni::Element::Cookie.new(
                    url:      @url,
                    name:     'mycookie',
                    value:    'myvalue',
                    httponly: true
                ).session?.should be_true
            end
        end

        context 'when cookie is not session cookie' do
            it 'returns false' do
                Arachni::Element::Cookie.new(
                    url:     @url,
                    name:    'mycookie',
                    value:   'myvalue',
                    expires: Time.now
                ).session?.should be_false
            end
        end
    end

    describe '#expired?' do
        context 'when expiry date is set' do
            context 'and has expired' do
                it 'returns true' do
                    Arachni::Element::Cookie.new(
                        url:     @url,
                        name:    '',
                        value:   '',
                        expires: Time.at( 0 )
                    ).expired?
                end
            end

            context 'and has not expired' do
                it 'returns false' do
                    Arachni::Element::Cookie.new(
                        url:     @url,
                        name:    '',
                        value:   '',
                        expires: Time.now + 999999
                    ).expired?.should be_false
                end
            end
        end

        context 'when not set' do
            it 'returns false' do
                @c.http_only?.should be_false
            end
        end
    end


    describe '#name' do
        it 'returns the name of the cookie' do
            @c.name.should == 'mycookie'
        end
    end

    describe '#value' do
        it 'returns the value of the cookie' do
            @c.value.should == 'myvalue'
        end
    end

    describe '#encode' do
        it 'encodes the string in a way that makes is suitable to be included in a cookie header' do
            Arachni::Element::Cookie.encode( 'some stuff ;%=' ).should == 'some+stuff+%3B%25%3D'
        end
    end

    describe '#to_s' do
        it 'returns a string representation of the cookie' do
            c = Arachni::Element::Cookie.new(
                url:    @url,
                name:  'blah=ha%',
                value: 'some stuff ;',
            )
            c.to_s.should == 'blah%3Dha%25=some+stuff+%3B'
        end
    end

    describe '#auditable=' do
        it 'properly encodes the value before storing it' do
            c = Arachni::Element::Cookie.new(
                url:   @url,
                name:  'blah',
                value: 'some stuff ;',
            )

            c.inputs.values.first.should == 'some stuff ;'
        end
    end

    describe '.from_file' do
        it 'parses a Netscape cookiejar file into an array of cookies' do
            cookies =  Arachni::Element::Cookie.from_file( @url, fixtures_path + 'cookies.txt' )
            cookies.size.should == 4

            cookie = cookies.shift
            cookie.action.should == @url
            cookie.url.should == @url
            cookie.inputs.should == { 'first_name' => 'first_value' }
            cookie.simple.should == { 'first_name' => 'first_value' }
            cookie.domain.should == '.domain.com'
            cookie.path.should == '/path/to/somewhere'
            cookie.secure.should == true
            cookie.session?.should == false
            cookie.expires.is_a?( Time ).should == true
            cookie.name.should == 'first_name'
            cookie.value.should == 'first_value'

            cookie = cookies.shift
            cookie.action.should == @url
            cookie.url.should == @url
            cookie.inputs.should == { 'second_name' => 'second_value' }
            cookie.simple.should == { 'second_name' => 'second_value' }
            cookie.domain.should == 'another-domain.com'
            cookie.path.should == '/'
            cookie.secure.should == false
            cookie.session?.should == true
            cookie.expires.should be_nil
            cookie.name.should == 'second_name'
            cookie.value.should == 'second_value'

            cookie = cookies.shift
            cookie.action.should == @url
            cookie.url.should == @url
            cookie.inputs.should == { 'NAME' => 'OP5jTLV6VhYHADJAbJ1ZR@L8~081210' }
            cookie.simple.should == { 'NAME' => 'OP5jTLV6VhYHADJAbJ1ZR@L8~081210' }
            cookie.domain.should == '.blah-domain'
            cookie.path.should == '/'
            cookie.secure.should == false
            cookie.session?.should == false
            cookie.expires.should == Time.parse( '2020-08-09 16:59:20 +0300' )
            cookie.name.should == 'NAME'
            cookie.value.should == 'OP5jTLV6VhYHADJAbJ1ZR@L8~081210'

            cookie = cookies.shift
            cookie.action.should == @url
            cookie.url.should == @url
            cookie.inputs.should == { '_superapp_session' => 'BAh7CkkiD3Nlc3Npb25faWQGOgZFRiIlNWMyOWY5MjE5YmU0MWMzMWM0ZGQxNTdkNzJkOTFmZTRJIhBfY3NyZl90b2tlbgY7AEZJIjF6RStYQzdONGxScUZybWxhbUwwUDI2RWZuai9laWVsS3FKRXhZYnlQUmJjPQY7AEZJIgtsb2NhbGUGOwBGSSIHZW4GOwBGSSIVdXNlcl9jcmVkZW50aWFscwY7AEZJIgGAOThiOGU5ZTcwMDFlOGI4N2IzNjQxMjlkNWYxNGExYzg3NjY5ZjE1ZjFjMDM3MWJiNjg1OGFlOTBlNjQxM2I1Y2JiODlkNTExMjU1MzBhMDk0ZjlmN2JlNjAyZTMzMjYxNzc5OGM2OTg1ZGRlYzgxNmFlZmEzYmRjNDk4YTBjNzcGOwBUSSIYdXNlcl9jcmVkZW50aWFsc19pZAY7AEZpBg%3D%3D--810acaa3759101ed79740e25de31e0c5bad76cdc' }
            cookie.simple.should == { '_superapp_session' => 'BAh7CkkiD3Nlc3Npb25faWQGOgZFRiIlNWMyOWY5MjE5YmU0MWMzMWM0ZGQxNTdkNzJkOTFmZTRJIhBfY3NyZl90b2tlbgY7AEZJIjF6RStYQzdONGxScUZybWxhbUwwUDI2RWZuai9laWVsS3FKRXhZYnlQUmJjPQY7AEZJIgtsb2NhbGUGOwBGSSIHZW4GOwBGSSIVdXNlcl9jcmVkZW50aWFscwY7AEZJIgGAOThiOGU5ZTcwMDFlOGI4N2IzNjQxMjlkNWYxNGExYzg3NjY5ZjE1ZjFjMDM3MWJiNjg1OGFlOTBlNjQxM2I1Y2JiODlkNTExMjU1MzBhMDk0ZjlmN2JlNjAyZTMzMjYxNzc5OGM2OTg1ZGRlYzgxNmFlZmEzYmRjNDk4YTBjNzcGOwBUSSIYdXNlcl9jcmVkZW50aWFsc19pZAY7AEZpBg%3D%3D--810acaa3759101ed79740e25de31e0c5bad76cdc' }
            cookie.domain.should == '192.168.1.1'
            cookie.path.should == '/'
            cookie.secure.should == false
            cookie.session?.should == true
            cookie.expires.should be_nil
            cookie.name.should == '_superapp_session'
            cookie.value.should == 'BAh7CkkiD3Nlc3Npb25faWQGOgZFRiIlNWMyOWY5MjE5YmU0MWMzMWM0ZGQxNTdkNzJkOTFmZTRJIhBfY3NyZl90b2tlbgY7AEZJIjF6RStYQzdONGxScUZybWxhbUwwUDI2RWZuai9laWVsS3FKRXhZYnlQUmJjPQY7AEZJIgtsb2NhbGUGOwBGSSIHZW4GOwBGSSIVdXNlcl9jcmVkZW50aWFscwY7AEZJIgGAOThiOGU5ZTcwMDFlOGI4N2IzNjQxMjlkNWYxNGExYzg3NjY5ZjE1ZjFjMDM3MWJiNjg1OGFlOTBlNjQxM2I1Y2JiODlkNTExMjU1MzBhMDk0ZjlmN2JlNjAyZTMzMjYxNzc5OGM2OTg1ZGRlYzgxNmFlZmEzYmRjNDk4YTBjNzcGOwBUSSIYdXNlcl9jcmVkZW50aWFsc19pZAY7AEZpBg==--810acaa3759101ed79740e25de31e0c5bad76cdc'
        end
    end

    describe '.from_response' do
        context 'when the response contains cookies' do
            it 'returns an array of cookies' do
                response = @http.get( @url + '/set_cookie', mode: :sync )
                cookies = Arachni::Element::Cookie.from_response( response )
                cookies.size.should == 1
                cookie = cookies.first
                cookie.name.should == 'my-cookie'
                cookie.value.should == 'my-val'
            end
        end
    end


    describe '.from_document' do
        context 'when there are any set-cookie attributes in http-equiv' do
            context 'with a String document' do
                it 'returns an array of cookies' do
                    html = <<-EOHTML
                    <html>
                    <head>
                        <meta http-equiv="Set-Cookie" content="cookie=val; httponly">
                        <meta http-equiv="Set-Cookie" content="cookie2=val2; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Path=/; Domain=.foo.com; HttpOnly; secure">
                    </head>
                    </html>
                    EOHTML

                    cookies = Arachni::Element::Cookie.from_document( 'http://test.com', html )
                    cookies.size.should == 2

                    cookie = cookies.shift
                    cookie.name.should == 'cookie'
                    cookie.value.should == 'val'
                    cookie.expired?.should == false
                    cookie.session?.should == true
                    cookie.secure?.should == false

                    cookie = cookies.shift
                    cookie.name.should == 'cookie2'
                    cookie.value.should == 'val2'
                    cookie.path.should == '/'
                    cookie.domain.should == '.foo.com'
                    cookie.secure?.should == true
                    cookie.expired?.should == true
                end
            end
            context 'with an empty string' do
                it 'returns an empty array' do
                     Arachni::Element::Cookie.from_document( '', '' ).should be_empty
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

                    cookies = Arachni::Element::Cookie.from_headers( 'http://test.com', headers )
                    cookies.size.should == 1
                    cookies.first.name.should == 'coo@ki e2'
                    cookies.first.value.should == 'blah val2@'
                end
            end
            context 'with an empty string' do
                it 'returns an empty array' do
                     Arachni::Element::Cookie.from_headers( '', {} ).should be_empty
                end
            end
        end
    end

    describe '.from_set_cookie' do
        it 'parses the contents of the Set-Cookie header field into cookies' do
            sc = "SomeCookie=MzE4OjEzNzU0Mzc0OTc4NDI6MmY3YzkxMTkwZDE5MTRmNjBlYjY4OGQ5ZjczMTU1ZTQzNGM2Y2IwNA%3D%3D"
            c1 = Arachni::Element::Cookie.from_set_cookie( 'http://test.com', sc ).first

            c1.should == Arachni::Element::Cookie.from_set_cookie( 'http://test.com', sc ).first

            sc2 = "SomeCookie=\"MzE4OjEzNzU0Mzc0OTc4NDI6MmY3YzkxMTkwZDE5MTRmNjBlYjY4OGQ5ZjczMTU1ZTQzNGM2Y2IwNA==\""
            c2 = Arachni::Element::Cookie.from_set_cookie( 'http://test.com', sc2 ).first

            c1.should == c2
            c1.name.should == 'SomeCookie'
            c1.value.should == 'MzE4OjEzNzU0Mzc0OTc4NDI6MmY3YzkxMTkwZDE5MTRmNjBlYjY4OGQ5ZjczMTU1ZTQzNGM2Y2IwNA=='

            sc3 = "coo%40ki+e2=blah+val2%40; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Path=/stuff; Domain=.foo.com; HttpOnly"
            cookies = Arachni::Element::Cookie.from_set_cookie( 'http://test.com', sc3 )
            cookies.size.should == 1
            cookie = cookies.first
            cookie.name.should == 'coo@ki e2'
            cookie.value.should == 'blah val2@'
            cookie.path.should == '/stuff'
        end

        context 'when there is no path' do
            it 'reverts to \'/\'' do
                sc3 = "coo%40ki+e2=blah+val2%40; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Domain=.foo.com; HttpOnly"
                cookies = Arachni::Element::Cookie.from_set_cookie( 'http://test.com/stuff', sc3 )
                cookies.size.should == 1
                cookie = cookies.first
                cookie.name.should == 'coo@ki e2'
                cookie.value.should == 'blah val2@'
                cookie.path.should == '/'
            end
        end
    end

    describe '.from_string' do
        it 'parses cookies formatted as a string' do
             cookies = Arachni::Element::Cookie.from_string( 'http://owner-url.com',
                "coo%40ki+e2=blah+val2%40;name=value;name2=value2")
             cookies.size.should == 3

             c = cookies.shift
             c.name.should == 'coo@ki e2'
             c.value.should == 'blah val2@'

             c = cookies.shift
             c.name.should == 'name'
             c.value.should == 'value'

             c = cookies.shift
             c.name.should == 'name2'
             c.value.should == 'value2'
        end
    end

end

