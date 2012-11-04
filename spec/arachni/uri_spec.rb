# encoding: utf-8

require_relative '../spec_helper'

describe Arachni::URI do

    before( :all ) do
        @urls = [
            'http://suche.test.net/search/pic/?mc=portale@galerie@suchtipp.suche@bilder&su=zürich',
            'http://suche.test.net/search/pic/?mc=portale@galerie@suchtipp.suche@bilder&su=zürich#fragment',
            'http://user:pass@suche.test.net/search/pic/?mc=portale@galerie@suchtipp.suche@bilder&su=zürich',
            'http://user:pass@suche.test.net/search/pic/?mc=portale@galerie@suchtipp.suche@bilder&su=zürich#fragment',
            'another/path',
            '/some/path',
            'http://test.com',
            'http://test.com/?stuff=test&ss=blah',
            'style.css',
            'http://test.com/path/here',
            'http://user@test.com/path/here',
            'http://user:pass@test.com/path/here',
            'http://user:pass@test.com:80/path/here',
            'http://user:pass@test.com:81/path/here',
            'http://user:pass@test.com:81/path/here?query=here&with=more vars',
            'http://user:pass@test.com:81/path/here?query=here&with=more vars#and-fragment',
            'http://localhost:4567',
            'http://localhost:4567/',
            'http://testfire.net/default.aspx',
            'http://testfire.net/Privacypolicy.aspx?sec=Careers&template=US',
            'http://testfire.net/disclaimer.htm?url=http://dd.d',
            'hTTp://user:password@tEsT.com:81///with/////path/another weird '+
                'path %"&*[$)?query=crap&other=$54$5466][(\'"#fragment',
            'http://test.com/login.php?goto?=domain.tld/index.php',
            'http://test.com:/stuff',
            'http://test.com/stuff?name=val&amp;name2=val2',
            'http://testfire.net/bank/queryxpath.aspx?__EVENTVALIDATION=%2FwEWAwLNx%2B2YBwKw59eKCgKcjoPABw%3D%3D&__VIEWSTATE=%2FwEPDwUKMTEzMDczNTAxOWRk&_ctl0%3A_ctl0%3AContent%3AMain%3AButton1=Query&_ctl0%3A_ctl0%3AContent%3AMain%3ATextBox1=Enter+title+%28e.g.+IBM%29%27%3Becho+287630581954%2B4196403186331128%3B%23',
            'http://192.168.0.232/dvwa/phpinfo.php?=PHPB8B5F2A0-3C92-11d3-A3A9-4C7B08C10000%23%5E%28%24%21%40%24%29%28%28%29%29%29%2A%2A%2A%2A%2A%2A&_arachni_trainer_c987fdb6d3955bd60191449bc465bb5ca760f60661fa4bcdf28736ae04aa2a1e=c987fdb6d3955bd60191449bc465bb5ca760f60661fa4bcdf28736ae04aa2a1e',
            'http://foo.com/user/login?user%5Bname%5D=bar&user%5Bpass%5D=asdasd%26asdihbasd'
        ]

        @ref_normalizer = proc do |p|
            n = Addressable::URI.parse( p ).normalize
            n.path.gsub!( /\/+/, '/' )
            n.fragment = nil
            Arachni::Utilities.html_decode( n.to_s )
        end

        @uri = Arachni::URI
    end

    before { @opts = Arachni::Options.instance.reset }

    describe '.URI' do
        it 'should parse and normalize the give string' do
            @urls.each do |url|
                uri = Arachni::URI( url )
                uri.is_a?( Arachni::URI ).should be_true
                uri.to_s.should == @ref_normalizer.call( url )
            end
        end
    end

    describe '.encode' do
        it 'should decode a URI' do
            uri = "my test.asp?name=ståle&car=saab"
            @uri.encode( uri ).should == 'my%20test.asp?name=st%C3%A5le&car=saab'
        end
    end

    describe '.decode' do
        it 'should decode a URI' do
            uri = 'my%20test.asp?name=st%C3%A5le&car=saab'
            @uri.decode( uri ).should == "my test.asp?name=ståle&car=saab"
        end
    end

    describe '.parser' do
        it 'should return a URI::Parser' do
            @uri.parser.class.should == ::URI::Parser
        end
    end

    describe '.parse' do
        it 'should parse a URI' do
            scheme   = 'http'
            user     = 'user'
            password = 'password'
            host     = 'subdomain.domainname.tld'
            path     = '/some/path'
            query    = 'param=val&param2=val2'

            uri = "#{scheme}://#{user}:#{password}@#{host}#{path}?#{query}"

            parsed_uri = @uri.parse( uri )

            parsed_uri.to_s.should == uri

            parsed_uri.scheme.should == scheme
            parsed_uri.user.should == user
            parsed_uri.password.should == password
            parsed_uri.host.should == host
            parsed_uri.path.should == path
            parsed_uri.query.should == query
        end
    end

    describe '.ruby_parse' do
        it 'should clean the URL' do
            @urls.each do |url|
                @uri.ruby_parse( url ).to_s.should == @ref_normalizer.call( url )
            end
        end
    end

    describe '.cheap_parse' do
        it 'should parse a URI and return its components as a hash' do
            scheme   = 'http'
            user     = 'user'
            password = 'password'
            host     = 'subdomain.domainname.tld'
            path     = '/some/path'
            query    = 'param=val&param2=val2'

            uri = "#{scheme}://#{user}:#{password}@#{host}/#{path}?#{query}"

            parsed_uri = @uri.cheap_parse( uri )

            parsed_uri[:scheme].should == scheme
            parsed_uri[:userinfo].should == user + ':' + password
            parsed_uri[:host].should == host
            parsed_uri[:path].should == path
            parsed_uri[:query].should == query

            parsed_uri = @uri.cheap_parse( "//#{user}:#{password}@#{host}/#{path}?#{query}" )

            parsed_uri[:scheme].should be_nil
            parsed_uri[:userinfo].should == user + ':' + password
            parsed_uri[:host].should == host
            parsed_uri[:path].should == path
            parsed_uri[:query].should == query
        end

        it 'should return a frozen hash (with frozen values)' do
            h = @uri.cheap_parse( 'http://test.com/stuff/' )

            raised = false
            begin
                h[:stuff] = 0
            rescue RuntimeError
                raised = true
            end
            raised.should be_true

            raised = false
            begin
                h[:path] << '/'
            rescue RuntimeError
                raised = true
            end
            raised.should be_true
        end
    end

    describe '.to_absolute' do
        it 'should convert a relative path to absolute using the reference URL' do
            abs  = 'http://test.com/blah/ha'
            rel  = '/test'
            rel2 = 'test2'
            @uri.to_absolute( rel, abs ).should == "http://test.com" + rel
            @uri.to_absolute( rel2, abs ).should == "http://test.com/blah/" + rel2
            @uri.to_absolute( rel2, abs + '/' ).should == "http://test.com/blah/ha/" + rel2

            rel = '//domain-name.com/stuff'
            @uri.to_absolute( rel, abs ).should == "http:" + rel
        end
    end

    describe '.normalize' do
        it 'should clean the URL' do
            @urls.each do |url|
                @uri.normalize( url ).should == @ref_normalizer.call( url )
            end
            with_whitespace = 'http://test.com/stuff '
            @uri.normalize( with_whitespace ).to_s.should == with_whitespace.strip
        end
    end

    describe '#initialize' do
        context String do
            it 'should normalize and parse the string' do
                @urls.each do |url|
                    uri = @uri.new( url )
                    uri.is_a?( Arachni::URI ).should be_true
                    uri.to_s.should == @ref_normalizer.call( url )
                end
            end
        end

        context Hash do
            it 'should normalize and construct a URI from a Hash of components' do
                @urls.each do |url|
                    uri = @uri.new( @uri.cheap_parse( url ) )
                    uri.is_a?( Arachni::URI ).should be_true
                    uri.to_s.should == @ref_normalizer.call( url )
                end
            end
        end

        context URI do
            it 'should normalize and construct a URI from a Hash of components' do
                @urls.each do |url|
                    uri = ::URI.parse( @uri.normalize( url ) )
                    uri.is_a?( ::URI ).should be_true

                    a_uri = @uri.new( url )
                    a_uri.is_a?( Arachni::URI ).should be_true
                    a_uri.to_s.should == @ref_normalizer.call( url )
                end
            end
        end

        context Arachni::URI do
            it 'should normalize and construct a URI from a Hash of components' do
                @urls.each do |url|
                    uri = @uri.new( url )
                    a_uri = @uri.new( uri )
                    a_uri.is_a?( Arachni::URI ).should be_true
                    a_uri.should == uri
                end
            end
        end

        context 'else' do
            it 'should raise a TypeError' do
                raised = false
                begin
                    @uri.new( [] )
                rescue TypeError
                    raised = true
                end
                raised.should be_true
            end
        end
    end

    describe '#==' do
        it 'should convert both objects to strings and compare them' do
            @urls.each do |url|
                normalized_str = @uri.normalize( url )
                uri = ::URI.parse( normalized_str )
                uri.is_a?( ::URI ).should be_true

                a_uri = @uri.new( url )
                a_uri.is_a?( Arachni::URI ).should be_true

                a_uri.should == uri
                a_uri.should == normalized_str
                a_uri.should == a_uri
            end
        end
    end

    describe '#to_absolute' do
        it 'should convert a self to absolute using the reference URL' do
            abs  = 'http://test.com/blah/ha'
            rel  = '/test'
            rel2 = 'test2'
            @uri.parse( rel ).to_absolute( abs ).should == "http://test.com" + rel
            @uri.parse( rel2 ).to_absolute( abs ).should == "http://test.com/blah/" + rel2
            @uri.parse( rel2 ).to_absolute( abs + '/' ).should == "http://test.com/blah/ha/" + rel2
        end
    end

    describe '#up_p_to_path' do
        it 'should return the URL up to its path component (no resource name, query, fragment, etc)' do
            url = 'http://test.com/path/goes/here.php?query=goes&here=.!#frag'
            @uri.parse( url ).up_to_path.should == 'http://test.com/path/goes/'

            url = 'http://test.com/path/goes/here/?query=goes&here=.!#frag'
            @uri.parse( url ).up_to_path.should == 'http://test.com/path/goes/here/'

            url = 'http://test.com/path/goes/here?query=goes&here=.!#frag'
            @uri.parse( url ).up_to_path.should == 'http://test.com/path/goes/here/'

            url = 'http://test.com'
            @uri.parse( url ).up_to_path.should == 'http://test.com/'

            url = 'http://test.com/'
            @uri.parse( url ).up_to_path.should == 'http://test.com/'
        end
    end

    describe '#domain' do
        it 'should remove the deepest subdomain from the host' do
            url = 'http://test.com/'
            @uri.parse( url ).domain.should == 'test.com'

            url = 'http://test/'
            @uri.parse( url ).domain.should == 'test'

            url = 'http://subdomain.test.com/'
            @uri.parse( url ).domain.should == 'test.com'

            url = 'http://deep.subdomain.test.com/'
            @uri.parse( url ).domain.should == 'subdomain.test.com'
        end
    end

    describe '#too_deep?' do
        before { @deep_url = @uri.parse( '/very/very/very/very/deep' ) }

        context 'when the directory depth of the URL\'s path is' do
            context 'not greater than the provided depth' do
                it 'should return false' do
                    @deep_url.too_deep?( -1 ).should be_false

                    @opts.depth_limit = 100
                    @deep_url.too_deep?( 100 ).should be_false
                end
            end

            context 'greater than the provided depth' do
                it 'should return true' do
                    @deep_url.too_deep?( 2 ).should be_true
                end
            end
        end
    end

    describe '#exclude?' do
        before { @exclude_url = @uri.parse( 'http://test.com/exclude/' ) }

        context 'when self matches the provided exclude rules' do
            it 'should return true' do
                rules = [ /exclude/ ]
                @exclude_url.exclude?( rules ).should be_true

                @exclude_url.exclude?( rules.first ).should be_true
            end
        end

        context 'when self does not match the provided exclude rules' do
            it 'should return false' do
                rules = [ /boo/ ]
                @exclude_url.exclude?( rules ).should be_false

                @exclude_url.exclude?( rules.first ).should be_false
            end
        end

        context 'when the provided rules are nil' do
            it 'should raise a TypeError' do
                raised = false
                begin
                    @exclude_url.exclude?( nil ).should be_true
                rescue TypeError
                    raised = true
                end
                raised.should be_true
            end
        end

    end

    describe '#include?' do
        before { @include_url = @uri.parse( 'http://test.com/include/' ) }

        context 'when self matches the provided include rules in' do
            it 'should return true' do
                rules = [ /include/ ]
                @include_url.include?( rules ).should be_true

                @include_url.include?( rules.first ).should be_true
            end
        end

        context 'when self does not match the provided include rules in' do
            it 'should return false' do
                rules = [ /boo/ ]
                @include_url.include?( rules ).should be_false

                @include_url.include?( rules.first ).should be_false
            end
        end

        context 'when the provided rules are empty' do
            it 'should return true' do
                @include_url.include?( [] ).should be_true
            end
        end

        context 'when the provided rules are nil' do
            it 'should raise a TypeError' do
                raised = false
                begin
                    @include_url.include?( nil ).should be_true
                rescue TypeError
                    raised = true
                end
                raised.should be_true
            end
        end
    end

    describe '#in_domain?' do
        before { @in_domain_url = @uri.parse( 'http://test.com' ) }

        context Arachni::URI do
            context true do
                it 'should include subdomains in the comparison' do
                    u = @uri.parse( 'http://boo.test.com' )
                    @in_domain_url.in_domain?( true, u ).should be_false

                    u = @uri.parse( 'http://test.com' )
                    @in_domain_url.in_domain?( true, u ).should be_true
                end
            end
            context false do
                it 'should not include subdomains in the comparison' do
                    u = @uri.parse( 'http://boo.test.com' )
                    @in_domain_url.in_domain?( false, u ).should be_true

                    u = @uri.parse( 'http://test.com' )
                    @in_domain_url.in_domain?( true, u ).should be_true
                end
            end
        end

        context URI do
            context true do
                it 'should include subdomains in the comparison' do
                    u = URI( 'http://boo.test.com' )
                    @in_domain_url.in_domain?( true, u ).should be_false
                end
            end
            context false do
                it 'should not include subdomains in the comparison' do
                    u = URI( 'http://boo.test.com' )
                    @in_domain_url.in_domain?( false, u ).should be_true
                end
            end
        end

        context Hash do
            context true do
                it 'should include subdomains in the comparison' do
                    h = @uri.cheap_parse( 'http://boo.test.com' )
                    @in_domain_url.in_domain?( true, h ).should be_false
                end
            end
            context false do
                it 'should not include subdomains in the comparison' do
                    h = @uri.cheap_parse( 'http://boo.test.com' )
                    @in_domain_url.in_domain?( false, h ).should be_true
                end
            end
        end

        context String do
            context true do
                it 'should include subdomains in the comparison' do
                    @in_domain_url.in_domain?( true, 'http://boo.test.com' ).should be_false
                end
            end
            context false do
                it 'should not include subdomains in the comparison' do
                    @in_domain_url.in_domain?( false, 'http://boo.test.com' ).should be_true
                end
            end
        end

        context 'else' do
            it 'should raise a TypeError' do
                raised = false
                begin
                    @in_domain_url.in_domain?( false, [] ).should be_true
                rescue TypeError
                    raised = true
                end
                raised.should be_true
            end
        end
    end
end
