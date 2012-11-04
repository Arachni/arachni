require_relative '../../spec_helper'

describe Arachni::HTTP::CookieJar do

    before do
        @jar = Arachni::HTTP::CookieJar.new
        @file = spec_path + '/fixtures/cookies.txt'
    end

    describe '.from_file' do
        it 'should load cookies from a Netscape cookie-jar file' do
            j = @jar.class.from_file( @file )
            cookies = j.cookies
            cookies.size.should == 4
            cookies.should == Arachni::Utilities.cookies_from_file( '', @file )
        end

        context 'when the provided file does not exist' do
            it 'should raise an exception' do
                raised = false
                begin
                    j = @jar.class.from_file( 'file' )
                rescue Arachni::Exceptions::NoCookieJar
                    raised = true
                end
                raised.should be_true
            end
        end
    end

    describe '#initialize' do
        it 'should return a new instance' do
            Arachni::HTTP::CookieJar.new.is_a?( Arachni::HTTP::CookieJar ).should be_true
        end

        context 'when a cookiejer option has been provided' do
            it 'should load cookies from a Netscape cookie-jar file' do
                j = @jar.class.from_file( @file )
                cookies = j.cookies
                cookies.size.should == 4
                cookies.should == Arachni::Utilities.cookies_from_file( '', @file )
            end
        end

        context 'when the provided file does not exist' do
            it 'should raise an exception' do
                raised = false
                begin
                    j = @jar.class.from_file( 'file' )
                rescue Arachni::Exceptions::NoCookieJar
                    raised = true
                end
                raised.should be_true
            end
        end
    end

    describe '#<<' do
        context 'when a cookie with that name does not already exist' do
            it 'should add the cookie to the jar' do
                cookie = Arachni::Utilities.cookies_from_file( '', @file ).first
                @jar.empty?.should be_true

                (@jar << cookie).should == @jar
                @jar.cookies.first.should == cookie

                @jar.empty?.should be_false
            end
        end
        context 'when a cookie with that name already exists' do
            it 'should update the jar (i.e. replace the cookie)' do
                cookie = Arachni::Utilities.cookies_from_file( '', @file ).first
                @jar.empty?.should be_true

                (@jar << cookie).should == @jar
                @jar.cookies.first.should == cookie

                c = cookie.dup
                c.auditable = { c.name => 'my val' }

                (@jar << c).should == @jar
                @jar.cookies.first.should == c

                @jar.empty?.should be_false
            end
        end
    end

    describe '#update' do
        context 'when cookies with the same name do not already exist' do
            it 'should add the cookies to the jar' do
                cookies = Arachni::Utilities.cookies_from_file( '', @file )
                @jar.empty?.should be_true

                @jar.update( cookies ).should == @jar
                @jar.cookies.should == cookies

                @jar.empty?.should be_false
            end
        end
        context 'when cookies with the same name already exist' do
            it 'should update the jar (i.e. replace the cookies)' do
                cookies = Arachni::Utilities.cookies_from_file( '', @file )
                @jar.empty?.should be_true

                @jar.update( cookies ).should == @jar
                @jar.cookies.should == cookies

                c = cookies.dup.map { |dc| dc.auditable = { dc.name => dc.name + '-updated' }; dc }
                @jar.update( c ).should == @jar
                @jar.cookies.should == c

                @jar.empty?.should be_false
            end
        end
    end

    describe '#for_url' do
        it 'should return all cookies for that particular URL' do
            cookies = {}
            cookies[:with_path] = Arachni::Element::Cookie.new( '',
                'name'  => 'my_cookie',
                'value' => 'my_value',
                'domain'=> 'domain.com',
                'path'  => '/my/path'
            )

            cookies[:without_path] = Arachni::Element::Cookie.new( '',
                'name'  => 'my_cookie1',
                'value' => 'my_value2',
                'domain'=> 'domain.com',
                'path'  => '/'
            )

            cookies[:another_domain] = Arachni::Element::Cookie.new( '',
                'name'  => 'my_cookie1',
                'value' => 'my_value2',
                'domain'=> 'mydomain.com',
                'path'  => '/'
            )

            cookies[:tailmatching] = Arachni::Element::Cookie.new( '',
                'name'  => 'tail_name',
                'value' => 'tail_value',
                'domain'=> '.mydomain.com',
                'path'  => '/'
            )

            cookies[:subdomain] = Arachni::Element::Cookie.new( '',
                'name'  => 'name',
                'value' => 'value',
                'domain'=> 'sub.domain.com',
                'path'  => '/'
            )

            cookies[:subdomain_tailmatching] = Arachni::Element::Cookie.new( '',
                'name'  => 'tail_name',
                'value' => 'tail_value',
                'domain'=> '.sub.domain.com',
                'path'  => '/'
            )

            cookies[:expired] = Arachni::Element::Cookie.new( '',
                'name'  => 'expired_name',
                'value' => 'expired_value',
                'domain'=> 'expired.com',
                'path'  => '/',
                'expires' => Time.now - 999999
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
            @jar << Arachni::Element::Cookie.new( '',
                'name'  => 'expired_name',
                'value' => 'expired_value',
                'domain'=> 'expired.com',
                'path'  => '/',
                'expires' => Time.now - 999999
            )
            @jar << Arachni::Element::Cookie.new( '',
                'name'  => 'my_name',
                'value' => 'my_value',
                'domain'=> 'domain.com',
                'path'  => '/',
            )
        end
        describe 'include_expired' do
            context true do
                it 'should return all cookies' do
                    @jar.cookies( true ).size.should == 2
                end
            end
            context false do
                it 'should return non expired cookies only' do
                    c = @jar.cookies( false )
                    c.size.should == 1
                    c.first.name.should == 'my_name'
                end
            end
            context 'nil' do
                it 'should return non expired cookies only' do
                    c = @jar.cookies( false )
                    c.size.should == 1
                    c.first.name.should == 'my_name'
                end
            end
        end
    end

    describe '#clear' do
        it 'should empty the jar' do
            @jar.load( @file )
            @jar.empty?.should be_false
            @jar.clear
            @jar.empty?.should be_true
        end
    end

    describe '#empty?' do
        context 'when the cookie jar is empty' do
            it 'should return true' do
                @jar.empty?.should be_true
            end
        end
        context 'when the cookie jar is not empty' do
            it 'should return false' do
                @jar.empty?.should be_true
                @jar.load( @file )
                @jar.empty?.should be_false
            end
        end
    end

    describe '#any?' do
        context 'when the cookie jar is empty' do
            it 'should return false' do
                @jar.any?.should be_false
            end
        end
        context 'when the cookie jar is not empty' do
            it 'should return true' do
                @jar.any?.should be_false
                @jar.load( @file )
                @jar.any?.should be_true
            end
        end
    end

end
