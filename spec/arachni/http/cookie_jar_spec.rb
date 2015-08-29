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
            expect(cookies.size).to eq(4)
            expect(cookies).to eq(cookies)
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
            expect(Arachni::HTTP::CookieJar.new.is_a?( Arachni::HTTP::CookieJar )).to be_truthy
        end

        context 'when a cookiejer option has been provided' do
            it 'loads cookies from a Netscape cookie-jar file' do
                j = subject.class.from_file( cookiejar_file )
                cookies = j.cookies
                expect(cookies.size).to eq(4)
                expect(cookies).to eq(Arachni::Utilities.cookies_from_file( '', cookiejar_file ))
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
                expect(subject.empty?).to be_truthy

                expect(subject << cookie).to eq(subject)
                expect(subject.cookies.first).to eq(cookie)

                expect(subject.empty?).to be_falsey
            end
        end
        context 'when a cookie with that name already exists' do
            it 'updates the jar (i.e. replace the cookie)' do
                expect(subject.empty?).to be_truthy

                expect(subject << cookie).to eq(subject)
                expect(subject.cookies.first).to eq(cookie)

                c = cookie.dup
                c.inputs = { c.name => 'my val' }

                expect(subject << c).to eq(subject)
                expect(subject.cookies.first).to eq(c)

                expect(subject.empty?).to be_falsey
            end
        end
    end

    describe '#update' do
        context 'when cookies with the same name do not already exist' do
            it 'adds the cookies to the jar' do
                expect(subject.empty?).to be_truthy

                expect(subject.update( cookies )).to eq(subject)
                expect(subject.cookies).to eq(cookies)

                expect(subject.empty?).to be_falsey
            end
        end
        context 'when cookies with the same name already exist' do
            it 'updates the jar (i.e. replace the cookies)' do
                expect(subject.empty?).to be_truthy

                expect(subject.update( cookies )).to eq(subject)
                expect(subject.cookies).to eq(cookies)

                c = cookies.dup.map { |dc| dc.inputs = { dc.name => dc.name + '-updated' }; dc }
                expect(subject.update( c )).to eq(subject)
                expect(subject.cookies).to eq(c)

                expect(subject.empty?).to be_falsey
            end
        end

        context 'when passed a' do
            context 'Arachni::Cookie' do
                it 'updates the cookie jar with it' do
                    c = Arachni::Cookie.new( url: 'http://test.com', inputs: { name: 'value' } )

                    expect(subject).to be_empty

                    subject.update( c )
                    expect(subject.cookies.first.name).to eq('name')
                    expect(subject.cookies.first.value).to eq('value')
                end
            end

            context 'Hash' do
                it 'converts it to Cookie and update the cookie jar with it' do
                    expect(subject).to be_empty

                    Arachni::Options.url = 'http://test.com'
                    subject.update( name: 'value' )
                    expect(subject.cookies.first.name).to eq('name')
                    expect(subject.cookies.first.value).to eq('value')
                end
            end

            context 'String' do
                it 'parses it into a Cookie and update the cookie jar with it' do
                    expect(subject).to be_empty

                    Arachni::Options.url = 'http://test.com'
                    subject.update( 'name=value' )
                    expect(subject.cookies.first.name).to eq('name')
                    expect(subject.cookies.first.value).to eq('value')
                end

                context 'when in the form of a Set-Cookie header' do
                    it 'parses it into a Cookie and update the cookie jar with it' do
                        expect(subject).to be_empty

                        Arachni::Options.url = 'http://test.com'
                        subject.update( 'some_param=9e4ca2cc0f18a49f7c1881f78bebf7df; path=/; expires=Wed, 02-Oct-2020 23:53:46 GMT; HttpOnly' )
                        expect(subject.cookies.first.name).to eq('some_param')
                        expect(subject.cookies.first.value).to eq('9e4ca2cc0f18a49f7c1881f78bebf7df')
                    end
                end

                context 'when in the form of a Set-Cookie header' do
                    it 'parses it into a Cookie and update the cookie jar with it' do
                        expect(subject).to be_empty

                        Arachni::Options.url = 'http://test.com'
                        subject.update( 'some_param=9e4ca2cc0f18a49f7c1881f78bebf7df; path=/; expires=Wed, 02-Oct-2020 23:53:46 GMT; HttpOnly' )
                        expect(subject.cookies.first.name).to eq('some_param')
                        expect(subject.cookies.first.value).to eq('9e4ca2cc0f18a49f7c1881f78bebf7df')
                    end
                end
            end

            context 'Array' do
                it 'iterates and if necessary parses the entries and update the cookie jar with them' do
                    expect(subject).to be_empty

                    Arachni::Options.url = 'http://test.com'
                    subject.update([
                        Arachni::Cookie.new(
                            url: 'http://test.com', inputs: { cookie_name: 'cookie_value' } ),
                        { hash_name: 'hash_value' },
                        'string_name=string_value'
                    ] )

                    cookies = subject.cookies

                    expect(cookies.size).to eq(3)

                    c = cookies.shift
                    expect(c.name).to eq('cookie_name')
                    expect(c.value).to eq('cookie_value')

                    c = cookies.shift
                    expect(c.name).to eq('hash_name')
                    expect(c.value).to eq('hash_value')

                    c = cookies.shift
                    expect(c.name).to eq('string_name')
                    expect(c.value).to eq('string_value')
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

            expect(subject.for_url( 'http://domain.com/my/path' )).to eq([cookies[:with_path], cookies[:without_path]])
            expect(subject.for_url( 'http://domain.com/my/path/' )).to eq([cookies[:with_path], cookies[:without_path]])
            expect(subject.for_url( 'http://domain.com' )).to eq([cookies[:without_path]])
            expect(subject.for_url( 'http://domain.com/' )).to eq([cookies[:without_path]])

            expect(subject.for_url( 'http://mydomain.com' )).to eq([cookies[:another_domain], cookies[:tailmatching]])
            expect(subject.for_url( 'http://sub.mydomain.com' )).to eq([cookies[:tailmatching]])
            expect(subject.for_url( 'http://deep.sub.mydomain.com' )).to eq([cookies[:tailmatching]])

            expect(subject.for_url( 'http://sub.domain.com' )).to eq([cookies[:subdomain], cookies[:subdomain_tailmatching]])
            expect(subject.for_url( 'http://deeeep.deep.sub.domain.com' )).to eq([cookies[:subdomain_tailmatching]])

            expect(subject.for_url( 'http://expired.com' )).to be_empty
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
            context 'true' do
                it 'returns all cookies' do
                    expect(subject.cookies( true ).size).to eq(2)
                end
            end
            context 'false' do
                it 'returns non expired cookies only' do
                    c = subject.cookies( false )
                    expect(c.size).to eq(1)
                    expect(c.first.name).to eq('my_name')
                end
            end
            context 'nil' do
                it 'returns non expired cookies only' do
                    c = subject.cookies( false )
                    expect(c.size).to eq(1)
                    expect(c.first.name).to eq('my_name')
                end
            end
        end
    end

    describe '#clear' do
        it 'empties the jar' do
            subject.load( cookiejar_file )
            expect(subject.empty?).to be_falsey
            subject.clear
            expect(subject.empty?).to be_truthy
        end
    end

    describe '#empty?' do
        context 'when the cookie jar is empty' do
            it 'returns true' do
                expect(subject.empty?).to be_truthy
            end
        end
        context 'when the cookie jar is not empty' do
            it 'returns false' do
                expect(subject.empty?).to be_truthy
                subject.load( cookiejar_file )
                expect(subject.empty?).to be_falsey
            end
        end
    end

    describe '#any?' do
        context 'when the cookie jar is empty' do
            it 'returns false' do
                expect(subject.any?).to be_falsey
            end
        end
        context 'when the cookie jar is not empty' do
            it 'returns true' do
                expect(subject.any?).to be_falsey
                subject.load( cookiejar_file )
                expect(subject.any?).to be_truthy
            end
        end
    end

    describe '#merge!' do
        it 'updates the cookie_jar with the cookies of another' do
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

            expect(subject.cookies).to eq([c, other.cookies].flatten)
        end
    end
end
