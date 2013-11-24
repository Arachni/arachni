require 'spec_helper'

describe Arachni::HTTP::CookieJar do

    before do
        @jar = Arachni::HTTP::CookieJar.new
        @file = fixtures_path + 'cookies.txt'
    end

    describe '.from_file' do
        it 'loads cookies from a Netscape cookie-jar file' do
            j = @jar.class.from_file( @file )
            cookies = j.cookies
            cookies.size.should == 4
            cookies.should == Arachni::Utilities.cookies_from_file( '', @file )
        end

        context 'when the provided file does not exist' do
            it 'raises Arachni::HTTP::CookieJar::Error::CookieJarFileNotFound' do
                trigger = proc { @jar.class.from_file( 'file' ) }

                expect { trigger.call }.to raise_error Arachni::Error
                expect { trigger.call }.to raise_error Arachni::HTTP::Error
                expect { trigger.call }.to raise_error Arachni::HTTP::CookieJar::Error
                expect { trigger.call }.to raise_error Arachni::HTTP::CookieJar::Error::CookieJarFileNotFound
            end
        end
    end

    describe '#initialize' do
        it 'returns a new instance' do
            Arachni::HTTP::CookieJar.new.is_a?( Arachni::HTTP::CookieJar ).should be_true
        end

        context 'when a cookiejer option has been provided' do
            it 'loads cookies from a Netscape cookie-jar file' do
                j = @jar.class.from_file( @file )
                cookies = j.cookies
                cookies.size.should == 4
                cookies.should == Arachni::Utilities.cookies_from_file( '', @file )
            end
        end

        context 'when the provided file does not exist' do
            it 'raises Arachni::HTTP::CookieJar::Error::CookieJarFileNotFound' do
                expect { @jar.class.from_file( 'file' ) }.to raise_error Arachni::HTTP::CookieJar::Error::CookieJarFileNotFound
            end
        end
    end

    describe '#<<' do
        context 'when a cookie with that name does not already exist' do
            it 'adds the cookie to the jar' do
                cookie = Arachni::Utilities.cookies_from_file( '', @file ).first
                @jar.empty?.should be_true

                (@jar << cookie).should == @jar
                @jar.cookies.first.should == cookie

                @jar.empty?.should be_false
            end
        end
        context 'when a cookie with that name already exists' do
            it 'updates the jar (i.e. replace the cookie)' do
                cookie = Arachni::Utilities.cookies_from_file( '', @file ).first
                @jar.empty?.should be_true

                (@jar << cookie).should == @jar
                @jar.cookies.first.should == cookie

                c = cookie.dup
                c.inputs = { c.name => 'my val' }

                (@jar << c).should == @jar
                @jar.cookies.first.should == c

                @jar.empty?.should be_false
            end
        end
    end

    describe '#update' do
        context 'when cookies with the same name do not already exist' do
            it 'adds the cookies to the jar' do
                cookies = Arachni::Utilities.cookies_from_file( '', @file )
                @jar.empty?.should be_true

                @jar.update( cookies ).should == @jar
                @jar.cookies.should == cookies

                @jar.empty?.should be_false
            end
        end
        context 'when cookies with the same name already exist' do
            it 'updates the jar (i.e. replace the cookies)' do
                cookies = Arachni::Utilities.cookies_from_file( '', @file )
                @jar.empty?.should be_true

                @jar.update( cookies ).should == @jar
                @jar.cookies.should == cookies

                c = cookies.dup.map { |dc| dc.inputs = { dc.name => dc.name + '-updated' }; dc }
                @jar.update( c ).should == @jar
                @jar.cookies.should == c

                @jar.empty?.should be_false
            end
        end

        context 'when passed a' do
            context Arachni::Cookie do
                it 'updates the cookie jar with it' do
                    c = Arachni::Cookie.new( url: 'http://test.com', inputs: { name: 'value' } )

                    @jar.should be_empty

                    @jar.update( c )
                    @jar.cookies.first.name.should == 'name'
                    @jar.cookies.first.value.should == 'value'
                end
            end

            context Hash do
                it 'converts it to Cookie and update the cookie jar with it' do
                    @jar.should be_empty

                    Arachni::Options.url = 'http://test.com'
                    @jar.update( name: 'value' )
                    @jar.cookies.first.name.should == 'name'
                    @jar.cookies.first.value.should == 'value'
                end
            end

            context String do
                it 'parses it into a Cookie and update the cookie jar with it' do
                    @jar.should be_empty

                    Arachni::Options.url = 'http://test.com'
                    @jar.update( 'name=value' )
                    @jar.cookies.first.name.should == 'name'
                    @jar.cookies.first.value.should == 'value'
                end

                context 'when in the form of a Set-Cookie header' do
                    it 'parses it into a Cookie and update the cookie jar with it' do
                        @jar.should be_empty

                        Arachni::Options.url = 'http://test.com'
                        @jar.update( 'some_param=9e4ca2cc0f18a49f7c1881f78bebf7df; path=/; expires=Wed, 02-Oct-2020 23:53:46 GMT; HttpOnly' )
                        @jar.cookies.first.name.should == 'some_param'
                        @jar.cookies.first.value.should == '9e4ca2cc0f18a49f7c1881f78bebf7df'
                    end
                end
            end

            context Array do
                it 'iterates and if necessary parses the entries and update the cookie jar with them' do
                    @jar.should be_empty

                    Arachni::Options.url = 'http://test.com'
                    @jar.update([
                        Arachni::Cookie.new(
                            url: 'http://test.com', inputs: { cookie_name: 'cookie_value' } ),
                        { hash_name: 'hash_value' },
                        'string_name=string_value'
                    ] )

                    cookies = @jar.cookies

                    cookies.size.should == 3

                    c = cookies.shift
                    c.name.should == 'cookie_name'
                    c.value.should == 'cookie_value'

                    c = cookies.shift
                    c.name.should == 'hash_name'
                    c.value.should == 'hash_value'

                    c = cookies.shift
                    c.name.should == 'string_name'
                    c.value.should == 'string_value'
                end
            end

        end
    end

    describe '#for_url' do
        it 'returns all cookies for that particular URL' do
            cookies = {}
            cookies[:with_path] = Arachni::Element::Cookie.new(
                url:    '',
                name:   'my_cookie',
                value:  'my_value',
                domain: 'domain.com',
                path:   '/my/path'
            )

            cookies[:without_path] = Arachni::Element::Cookie.new(
                url:    '',
                name:   'my_cookie1',
                value:  'my_value2',
                domain: 'domain.com',
                path:   '/'
            )

            cookies[:another_domain] = Arachni::Element::Cookie.new(
                url:    '',
                name:   'my_cookie1',
                value:  'my_value2',
                domain: 'mydomain.com',
                path:   '/'
            )

            cookies[:tailmatching] = Arachni::Element::Cookie.new(
                url:    '',
                name:   'tail_name',
                value:  'tail_value',
                domain: '.mydomain.com',
                path:   '/'
            )

            cookies[:subdomain] = Arachni::Element::Cookie.new(
                url:    '',
                name:   'name',
                value:  'value',
                domain: 'sub.domain.com',
                path:   '/'
            )

            cookies[:subdomain_tailmatching] = Arachni::Element::Cookie.new(
                url:    '',
                name:   'tail_name',
                value:  'tail_value',
                domain: '.sub.domain.com',
                path:   '/'
            )

            cookies[:expired] = Arachni::Element::Cookie.new(
                url:    '',
                name:   'expired_name',
                value:  'expired_value',
                domain: 'expired.com',
                path:   '/',
                expires: Time.now - 999999
            )

            @jar.update( cookies.values )

            @jar.for_url( 'http://domain.com/my/path' ).should == [cookies[:with_path], cookies[:without_path]]
            @jar.for_url( 'http://domain.com/my/path/' ).should == [cookies[:with_path], cookies[:without_path]]
            @jar.for_url( 'http://domain.com' ).should == [cookies[:without_path]]
            @jar.for_url( 'http://domain.com/' ).should == [cookies[:without_path]]

            @jar.for_url( 'http://mydomain.com' ).should == [cookies[:another_domain], cookies[:tailmatching]]
            @jar.for_url( 'http://sub.mydomain.com' ).should == [cookies[:tailmatching]]
            @jar.for_url( 'http://deep.sub.mydomain.com' ).should == [cookies[:tailmatching]]

            @jar.for_url( 'http://sub.domain.com' ).should == [cookies[:subdomain], cookies[:subdomain_tailmatching]]
            @jar.for_url( 'http://deeeep.deep.sub.domain.com' ).should == [cookies[:subdomain_tailmatching]]

            @jar.for_url( 'http://expired.com' ).should be_empty
        end
    end

    describe '#cookies' do
        before( :each ) do
            @jar << Arachni::Element::Cookie.new(
                url:     '',
                name:    'expired_name',
                value:   'expired_value',
                domain:  'expired.com',
                path:    '/',
                expires: Time.now - 999999
            )
            @jar << Arachni::Element::Cookie.new(
                url:    '',
                name:   'my_name',
                value:  'my_value',
                domain: 'domain.com',
                path:   '/',
            )
        end
        describe 'include_expired' do
            context true do
                it 'returns all cookies' do
                    @jar.cookies( true ).size.should == 2
                end
            end
            context false do
                it 'returns non expired cookies only' do
                    c = @jar.cookies( false )
                    c.size.should == 1
                    c.first.name.should == 'my_name'
                end
            end
            context 'nil' do
                it 'returns non expired cookies only' do
                    c = @jar.cookies( false )
                    c.size.should == 1
                    c.first.name.should == 'my_name'
                end
            end
        end
    end

    describe '#clear' do
        it 'empties the jar' do
            @jar.load( @file )
            @jar.empty?.should be_false
            @jar.clear
            @jar.empty?.should be_true
        end
    end

    describe '#empty?' do
        context 'when the cookie jar is empty' do
            it 'returns true' do
                @jar.empty?.should be_true
            end
        end
        context 'when the cookie jar is not empty' do
            it 'returns false' do
                @jar.empty?.should be_true
                @jar.load( @file )
                @jar.empty?.should be_false
            end
        end
    end

    describe '#any?' do
        context 'when the cookie jar is empty' do
            it 'returns false' do
                @jar.any?.should be_false
            end
        end
        context 'when the cookie jar is not empty' do
            it 'returns true' do
                @jar.any?.should be_false
                @jar.load( @file )
                @jar.any?.should be_true
            end
        end
    end

end
