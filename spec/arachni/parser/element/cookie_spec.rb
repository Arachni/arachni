require_relative '../../../spec_helper'

describe Arachni::Parser::Element::Cookie do
    before( :all ) do
        @url = server_url_for( :cookie )
        @raw = { 'mycookie' => 'myvalue' }
        @c = Arachni::Parser::Element::Cookie.new( @url, @raw )
        @http = Arachni::HTTP.instance
    end

    describe :submit do
        it 'should perform the appropriate HTTP request with appropriate params' do
            body_should = @c.auditable.map { |k, v| k.to_s + v.to_s }.join( "\n" )
            body = nil
            @c.submit.on_complete {
                |res|
                body = res.body
            }
            @http.run
            body_should.should == body
        end
    end

    context 'when initialized' do
        context 'with hash key/pair' do
            describe :simple do
                it 'should return name/val as a key/pair' do
                    raw = { 'name' => 'val' }
                    c = Arachni::Parser::Element::Cookie.new( @url, raw )
                    c.simple.should == raw
                end
            end
        end
        context 'with attributes' do
            describe :simple do
                it 'should return name/val as a key/pair' do
                    raw = { 'name' => 'myname', 'value' => 'myvalue' }
                    c = Arachni::Parser::Element::Cookie.new( @url, raw )
                    c.simple.should == { raw['name'] => raw['value'] }
                end
            end
        end
    end

    describe :type do
        it 'should be "cookie"' do
            @c.type.should == 'cookie'
        end
    end

    describe :secure? do
        context 'when set' do
            it 'should return true' do
                Arachni::Parser::Element::Cookie.new( @url,
                    'name'   => 'mycookie',
                    'value'  => 'myvalue',
                    'secure' => true
                ).secure?.should be_true
            end
        end

        context 'when not set' do
            it 'should return false' do
                @c.secure?.should be_false
            end
        end
    end

    describe :httponly? do
        context 'when set' do
            it 'should return true' do
                Arachni::Parser::Element::Cookie.new( @url,
                    'name'   => 'mycookie',
                    'value'  => 'myvalue',
                    'httponly' => true
                ).http_only?.should be_true
            end
        end

        context 'when not set' do
            it 'should return false' do
                @c.http_only?.should be_false
            end
        end
    end

    describe :session? do
        context 'when cookie is session cookie' do
            it 'should return true' do
                Arachni::Parser::Element::Cookie.new( @url,
                    'name'   => 'mycookie',
                    'value'  => 'myvalue',
                    'httponly' => true
                ).session?.should be_true
            end
        end

        context 'when cookie is not session cookie' do
            it 'should return false' do
                Arachni::Parser::Element::Cookie.new( @url,
                    'name'   => 'mycookie',
                    'value'  => 'myvalue',
                    'expires' => Time.now
                ).session?.should be_false
            end
        end
    end

    describe :expired? do
        context 'when expiry date is set' do
            context 'and has expired' do
                it 'should return true' do
                    Arachni::Parser::Element::Cookie.new( @url,
                        'name'  => '',
                        'value' => '',
                        'expires' => Time.at( 0 )
                    ).expired?
                end
            end

            context 'and has not expired' do
                it 'should return false' do
                    Arachni::Parser::Element::Cookie.new( @url,
                        'name'  => '',
                        'value' => '',
                        'expires' => Time.now + 999999
                    ).expired?.should be_false
                end
            end
        end

        context 'when not set' do
            it 'should return false' do
                @c.http_only?.should be_false
            end
        end
    end


    describe :name do
        it 'should return the name of the cookie' do
            @c.name.should == 'mycookie'
        end
    end

    describe :value do
        it 'should return the name of the cookie' do
            @c.value.should == 'myvalue'
        end
    end

    describe :to_s do
        it 'should return a string representation of the cookie' do
            @c.to_s.should == "#{@c.name}=#{@c.value}"
        end
    end

    describe :from_response do
        context 'when the response contains cookies' do
            it 'should return an array of cookies' do
                response = @http.get( @url + '/set_cookie', async: false ).response
                cookies = Arachni::Parser::Element::Cookie.from_response( response )
                cookies.size.should == 1
                cookie = cookies.first
                cookie.name.should == 'my-cookie'
                cookie.value.should == 'my-val'
            end
        end
    end


    describe :from_document do
        context 'when there are any set-cookie attributes in http-equiv' do
            context 'with a String document' do
                it 'should return an array of cookies' do
                    html = <<-EOHTML
                    <html>
                    <head>
                        <meta http-equiv="Set-Cookie" content="cookie=val; httponly">
                        <meta http-equiv="Set-Cookie" content="cookie2=val2; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Path=/; Domain=.foo.com; HttpOnly; secure">
                    </head>
                    </html>
                    EOHTML

                    cookies = Arachni::Parser::Element::Cookie.from_document( 'http://test.com', html )
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
            context 'with a Nokogiri::HTML::Document' do
                it 'should return an array of cookies' do
                     Arachni::Parser::Element::Cookie.from_document( '', '' ).should be_empty
                end
            end
        end
    end

    describe :from_headers do
        context 'when there are any set-cookie attributes in http-equiv' do
            context 'with a String document' do
                it 'should return an array of cookies' do
                    headers = {
                        'set-cookie' => "cookie2=val2; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Path=/; Domain=.foo.com; HttpOnly"
                    }

                    cookies = Arachni::Parser::Element::Cookie.from_headers( 'http://test.com', headers )
                    cookies.size.should == 1
                end
            end
            context 'with a Nokogiri::HTML::Document' do
                it 'should return an array of cookies' do
                     Arachni::Parser::Element::Cookie.from_headers( '', {} ).should be_empty
                end
            end
        end
    end

end
