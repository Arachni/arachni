require 'spec_helper'

describe Arachni::HTTP::CookieJar do

    subject { described_class.new }
    let(:cookies) { Arachni::Utilities.cookies_from_file( '', cookiejar_file ) }
    let(:cookie) { cookies.first }
    let(:cookiejar_file) { fixtures_path + 'cookies.txt' }

    describe '.from_file' do
        it 'loads cookies from a Netscape cookie-jar file' do
            j = subject.class.from_file( cookiejar_file )
            cookies = j.cookies
            cookies.size.should == 4
            cookies.should == cookies
        end

        context 'when the provided file does not exist' do
            it 'raises Arachni::HTTP::CookieJar::Error::CookieJarFileNotFound' do
                trigger = proc { subject.class.from_file( 'file' ) }

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
                j = subject.class.from_file( cookiejar_file )
                cookies = j.cookies
                cookies.size.should == 4
                cookies.should == Arachni::Utilities.cookies_from_file( '', cookiejar_file )
            end
        end

        context 'when the provided file does not exist' do
            it 'raises Arachni::HTTP::CookieJar::Error::CookieJarFileNotFound' do
                expect { subject.class.from_file( 'file' ) }.to raise_error Arachni::HTTP::CookieJar::Error::CookieJarFileNotFound
            end
        end
    end

    describe '#<<' do
        context 'when a cookie with that name does not already exist' do
            it 'adds the cookie to the jar' do
                subject.empty?.should be_true

                (subject << cookie).should == subject
                subject.cookies.first.should == cookie

                subject.empty?.should be_false
            end
        end
        context 'when a cookie with that name already exists' do
            it 'updates the jar (i.e. replace the cookie)' do
                subject.empty?.should be_true

                (subject << cookie).should == subject
                subject.cookies.first.should == cookie

                c = cookie.dup
                c.inputs = { c.name => 'my val' }

                (subject << c).should == subject
                subject.cookies.first.should == c

                subject.empty?.should be_false
            end
        end
    end

    describe '#update' do
        context 'when cookies with the same name do not already exist' do
            it 'adds the cookies to the jar' do
                subject.empty?.should be_true

                subject.update( cookies ).should == subject
                subject.cookies.should == cookies

                subject.empty?.should be_false
            end
        end
        context 'when cookies with the same name already exist' do
            it 'updates the jar (i.e. replace the cookies)' do
                subject.empty?.should be_true

                subject.update( cookies ).should == subject
                subject.cookies.should == cookies

                c = cookies.dup.map { |dc| dc.inputs = { dc.name => dc.name + '-updated' }; dc }
                subject.update( c ).should == subject
                subject.cookies.should == c

                subject.empty?.should be_false
            end
        end

        context 'when passed a' do
            context Arachni::Cookie do
                it 'updates the cookie jar with it' do
                    c = Arachni::Cookie.new( url: 'http://test.com', inputs: { name: 'value' } )

                    subject.should be_empty

                    subject.update( c )
                    subject.cookies.first.name.should == 'name'
                    subject.cookies.first.value.should == 'value'
                end
            end

            context Hash do
                it 'converts it to Cookie and update the cookie jar with it' do
                    subject.should be_empty

                    Arachni::Options.url = 'http://test.com'
                    subject.update( name: 'value' )
                    subject.cookies.first.name.should == 'name'
                    subject.cookies.first.value.should == 'value'
                end
            end

            context String do
                it 'parses it into a Cookie and update the cookie jar with it' do
                    subject.should be_empty

                    Arachni::Options.url = 'http://test.com'
                    subject.update( 'name=value' )
                    subject.cookies.first.name.should == 'name'
                    subject.cookies.first.value.should == 'value'
                end

                context 'when in the form of a Set-Cookie header' do
                    it 'parses it into a Cookie and update the cookie jar with it' do
                        subject.should be_empty

                        Arachni::Options.url = 'http://test.com'
                        subject.update( 'some_param=9e4ca2cc0f18a49f7c1881f78bebf7df; path=/; expires=Wed, 02-Oct-2020 23:53:46 GMT; HttpOnly' )
                        subject.cookies.first.name.should == 'some_param'
                        subject.cookies.first.value.should == '9e4ca2cc0f18a49f7c1881f78bebf7df'
                    end
                end
            end

            context Array do
                it 'iterates and if necessary parses the entries and update the cookie jar with them' do
                    subject.should be_empty

                    Arachni::Options.url = 'http://test.com'
                    subject.update([
                        Arachni::Cookie.new(
                            url: 'http://test.com', inputs: { cookie_name: 'cookie_value' } ),
                        { hash_name: 'hash_value' },
                        'string_name=string_value'
                    ] )

                    cookies = subject.cookies

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

            subject.update( cookies.values )

            subject.for_url( 'http://domain.com/my/path' ).should == [cookies[:with_path], cookies[:without_path]]
            subject.for_url( 'http://domain.com/my/path/' ).should == [cookies[:with_path], cookies[:without_path]]
            subject.for_url( 'http://domain.com' ).should == [cookies[:without_path]]
            subject.for_url( 'http://domain.com/' ).should == [cookies[:without_path]]

            subject.for_url( 'http://mydomain.com' ).should == [cookies[:another_domain], cookies[:tailmatching]]
            subject.for_url( 'http://sub.mydomain.com' ).should == [cookies[:tailmatching]]
            subject.for_url( 'http://deep.sub.mydomain.com' ).should == [cookies[:tailmatching]]

            subject.for_url( 'http://sub.domain.com' ).should == [cookies[:subdomain], cookies[:subdomain_tailmatching]]
            subject.for_url( 'http://deeeep.deep.sub.domain.com' ).should == [cookies[:subdomain_tailmatching]]

            subject.for_url( 'http://expired.com' ).should be_empty
        end
    end

    describe '#cookies' do
        before( :each ) do
            subject << Arachni::Element::Cookie.new(
                url:     '',
                name:    'expired_name',
                value:   'expired_value',
                domain:  'expired.com',
                path:    '/',
                expires: Time.now - 999999
            )
            subject << Arachni::Element::Cookie.new(
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
                    subject.cookies( true ).size.should == 2
                end
            end
            context false do
                it 'returns non expired cookies only' do
                    c = subject.cookies( false )
                    c.size.should == 1
                    c.first.name.should == 'my_name'
                end
            end
            context 'nil' do
                it 'returns non expired cookies only' do
                    c = subject.cookies( false )
                    c.size.should == 1
                    c.first.name.should == 'my_name'
                end
            end
        end
    end

    describe '#clear' do
        it 'empties the jar' do
            subject.load( cookiejar_file )
            subject.empty?.should be_false
            subject.clear
            subject.empty?.should be_true
        end
    end

    describe '#empty?' do
        context 'when the cookie jar is empty' do
            it 'returns true' do
                subject.empty?.should be_true
            end
        end
        context 'when the cookie jar is not empty' do
            it 'returns false' do
                subject.empty?.should be_true
                subject.load( cookiejar_file )
                subject.empty?.should be_false
            end
        end
    end

    describe '#any?' do
        context 'when the cookie jar is empty' do
            it 'returns false' do
                subject.any?.should be_false
            end
        end
        context 'when the cookie jar is not empty' do
            it 'returns true' do
                subject.any?.should be_false
                subject.load( cookiejar_file )
                subject.any?.should be_true
            end
        end
    end

    describe '#merge!' do
        it 'updates the cookiejar with the cookies of another' do
            other = subject.class.from_file( cookiejar_file )

            c = Arachni::Element::Cookie.new(
                url:    '',
                name:   'my_name',
                value:  'my_value',
                domain: 'domain.com',
                path:   '/',
            )
            subject << c
            subject.merge! other

            subject.cookies.should == [c, other.cookies].flatten
        end
    end
end
