# encoding: utf-8

require 'spec_helper'

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
            'http://foo.com/user/login?user%5Bname%5D=bar&user%5Bpass%5D=asdasd%26asdihbasd',
            'http://stuff.host.fdfd/web/seguros/auto;jsessionid=6CB5A6A4597FFFA80C4D23B235072588.000?test=tet'
        ]

        @normalized = {
            "http://suche.test.net/search/pic/?mc=portale@galerie@suchtipp.suche@bilder&su=zürich"=>
               "http://suche.test.net/search/pic/?mc=portale@galerie@suchtipp.suche@bilder&su=z%C3%BCrich",
           "http://suche.test.net/search/pic/?mc=portale@galerie@suchtipp.suche@bilder&su=zürich#fragment"=>
               "http://suche.test.net/search/pic/?mc=portale@galerie@suchtipp.suche@bilder&su=z%C3%BCrich",
           "http://user:pass@suche.test.net/search/pic/?mc=portale@galerie@suchtipp.suche@bilder&su=zürich"=>
               "http://user:pass@suche.test.net/search/pic/?mc=portale@galerie@suchtipp.suche@bilder&su=z%C3%BCrich",
           "http://user:pass@suche.test.net/search/pic/?mc=portale@galerie@suchtipp.suche@bilder&su=zürich#fragment"=>
               "http://user:pass@suche.test.net/search/pic/?mc=portale@galerie@suchtipp.suche@bilder&su=z%C3%BCrich",
           "another/path"=>"another/path",
           "/some/path"=>"/some/path",
           "http://test.com"=>"http://test.com/",
           "http://test.com/?stuff=test&ss=blah"=>"http://test.com/?stuff=test&ss=blah",
           "style.css"=>"style.css",
           "http://test.com/path/here"=>"http://test.com/path/here",
           "http://user@test.com/path/here"=>"http://user@test.com/path/here",
           "http://user:pass@test.com/path/here"=>"http://user:pass@test.com/path/here",
           "http://user:pass@test.com:80/path/here"=>
               "http://user:pass@test.com/path/here",
           "http://user:pass@test.com:81/path/here"=>
               "http://user:pass@test.com:81/path/here",
           "http://user:pass@test.com:81/path/here?query=here&with=more vars"=>
               "http://user:pass@test.com:81/path/here?query=here&with=more%20vars",
           "http://user:pass@test.com:81/path/here?query=here&with=more vars#and-fragment"=>
               "http://user:pass@test.com:81/path/here?query=here&with=more%20vars",
           "http://localhost:4567"=>"http://localhost:4567/",
           "http://localhost:4567/"=>"http://localhost:4567/",
           "http://testfire.net/default.aspx"=>"http://testfire.net/default.aspx",
           "http://testfire.net/Privacypolicy.aspx?sec=Careers&template=US"=>
               "http://testfire.net/Privacypolicy.aspx?sec=Careers&template=US",
           "http://testfire.net/disclaimer.htm?url=http://dd.d"=>
               "http://testfire.net/disclaimer.htm?url=http://dd.d",
           "hTTp://user:password@tEsT.com:81///with/////path/another weird path %\"&*[$)?query=crap&other=$54$5466][('\"#fragment"=>
               "http://user:password@test.com:81/with/path/another%20weird%20path%20%25%22&*%5B$)?query=crap&other=$54$5466%5D%5B('%22",
           "http://test.com/login.php?goto?=domain.tld/index.php"=>
               "http://test.com/login.php?goto?=domain.tld/index.php",
           "http://test.com:/stuff"=>"http://test.com/stuff",
           "http://test.com/stuff?name=val&amp;name2=val2"=>
               "http://test.com/stuff?name=val&name2=val2",
           "http://testfire.net/bank/queryxpath.aspx?__EVENTVALIDATION=%2FwEWAwLNx%2B2YBwKw59eKCgKcjoPABw%3D%3D&__VIEWSTATE=%2FwEPDwUKMTEzMDczNTAxOWRk&_ctl0%3A_ctl0%3AContent%3AMain%3AButton1=Query&_ctl0%3A_ctl0%3AContent%3AMain%3ATextBox1=Enter+title+%28e.g.+IBM%29%27%3Becho+287630581954%2B4196403186331128%3B%23"=>
               "http://testfire.net/bank/queryxpath.aspx?__EVENTVALIDATION=/wEWAwLNx+2YBwKw59eKCgKcjoPABw==&__VIEWSTATE=/wEPDwUKMTEzMDczNTAxOWRk&_ctl0:_ctl0:Content:Main:Button1=Query&_ctl0:_ctl0:Content:Main:TextBox1=Enter+title+(e.g.+IBM)';echo+287630581954+4196403186331128;%23",
           "http://192.168.0.232/dvwa/phpinfo.php?=PHPB8B5F2A0-3C92-11d3-A3A9-4C7B08C10000%23%5E%28%24%21%40%24%29%28%28%29%29%29%2A%2A%2A%2A%2A%2A&_arachni_trainer_c987fdb6d3955bd60191449bc465bb5ca760f60661fa4bcdf28736ae04aa2a1e=c987fdb6d3955bd60191449bc465bb5ca760f60661fa4bcdf28736ae04aa2a1e"=>
               "http://192.168.0.232/dvwa/phpinfo.php?=PHPB8B5F2A0-3C92-11d3-A3A9-4C7B08C10000%23%5E($!@$)(()))******&_arachni_trainer_c987fdb6d3955bd60191449bc465bb5ca760f60661fa4bcdf28736ae04aa2a1e=c987fdb6d3955bd60191449bc465bb5ca760f60661fa4bcdf28736ae04aa2a1e",
           "http://foo.com/user/login?user%5Bname%5D=bar&user%5Bpass%5D=asdasd%26asdihbasd"=>
               "http://foo.com/user/login?user%5Bname%5D=bar&user%5Bpass%5D=asdasd%26asdihbasd",
           "http://stuff.host.fdfd/web/seguros/auto;jsessionid=6CB5A6A4597FFFA80C4D23B235072588.000?test=tet"=>
               "http://stuff.host.fdfd/web/seguros/auto?test=tet"
        }

        @ref_normalizer = proc do |p|
            @normalized[p]
        end
    end

    before(:each) { @opts = Arachni::Options.instance.reset }

    let(:rewrite_rules) do
        { /articles\/[\w-]+\/(\d+)/ => 'articles.php?id=\1' }
    end

    describe '.URI' do
        it 'parses and normalize the give string' do
            @urls.each do |url|
                uri = Arachni::URI( url )
                uri.is_a?( Arachni::URI ).should be_true
                uri.to_s.should == @ref_normalizer.call( url )
            end
        end
    end

    describe '.rewrite' do
        let(:url) { 'http://test.com/articles/some-stuff/23' }

        it 'rewrites a URL based on the given rules' do
            described_class.rewrite( url, rewrite_rules ).should ==
                'http://test.com/articles.php?id=23'
        end

        context 'when no rules are provided' do
            it "uses the ones in #{Arachni::OptionGroups::Scope}#url_rewrites" do
                Arachni::Options.scope.url_rewrites = rewrite_rules

                described_class.rewrite( url ).should ==
                    'http://test.com/articles.php?id=23'
            end
        end
    end

    describe '.parse_query' do
        it 'returns the query parameters as a Hash' do
            url = 'http://test/?param_one=value_one&param_two=value_two'
            described_class.parse_query( url ).should == {
                'param_one' => 'value_one',
                'param_two' => 'value_two'
            }
        end

        it 'decodes the parameters' do
            url = 'http://test/?stuff%20here=bl%20ah'
            described_class.parse_query( url ).should == {
                'stuff here' => 'bl ah'
            }
        end

        context 'when passed' do
            describe 'nil' do
                it 'returns an empty Hash' do
                    described_class.parse_query( nil ).should == {}
                end
            end
            describe 'an unparsable URL' do
                it 'returns an empty Hash' do
                    url = '$#%^$6#5436#$%^'
                    described_class.parse_query( url ).should == {}
                end
            end
        end
    end

    describe '.encode' do
        it 'decodes a URI' do
            uri = "my test.asp?name=ståle&car=saab"
            described_class.encode( uri ).should == 'my%20test.asp?name=st%C3%A5le&car=saab'
        end
    end

    describe '.decode' do
        it 'decodes a URI' do
            uri = 'my%20test.asp?name=st%C3%A5le&car=saab'
            described_class.decode( uri ).should == "my test.asp?name=ståle&car=saab"
        end
    end

    describe '.parser' do
        it 'returns a URI::Parser' do
            described_class.parser.class.should == ::URI::Parser
        end
    end

    describe '.parse' do
        it 'parses a URI' do
            scheme   = 'http'
            user     = 'user'
            password = 'password'
            host     = 'subdomain.domainname.tld'
            path     = '/some/path'
            query    = 'param=val&param2=val2'

            uri = "#{scheme}://#{user}:#{password}@#{host}#{path}?#{query}"

            parsed_uri = described_class.parse( uri )

            parsed_uri.to_s.should == uri

            parsed_uri.scheme.should == scheme
            parsed_uri.user.should == user
            parsed_uri.password.should == password
            parsed_uri.host.should == host
            parsed_uri.path.should == path
            parsed_uri.query.should == query
        end

        it 'ignores javascript: URLs' do
            described_class.parse( 'javascript:stuff()' ).should be_nil
            described_class.parse( 'jAvaScRipT:stuff()' ).should be_nil
        end
    end

    describe '.ruby_parse' do
        it 'cleans the URL' do
            @urls.each do |url|
                described_class.ruby_parse( url ).to_s.should == @ref_normalizer.call( url )
            end
        end

        it 'ignores javascript: URLs' do
            described_class.ruby_parse( 'javascript:stuff()' ).should be_nil
            described_class.ruby_parse( 'jAvaScRipT:stuff()' ).should be_nil
        end

        context 'when an error occurs' do
            it 'returns nil' do
                described_class.stub(:fast_parse){ raise }
                described_class.stub(:normalize){ raise }

                described_class.ruby_parse( 'http://test.com/222' ).should be_nil
            end
        end
    end

    describe '.fast_parse' do
        it 'parses a URI and return its components as a hash' do
            scheme   = 'http'
            user     = 'user'
            password = 'password'
            host     = 'subdomain.domainname.tld'
            path     = '/some/path'
            query    = 'param=val&param2=val2'

            uri = "#{scheme}://#{user}:#{password}@#{host}/#{path}?#{query}"

            parsed_uri = described_class.fast_parse( uri )

            parsed_uri[:scheme].should == scheme
            parsed_uri[:userinfo].should == user + ':' + password
            parsed_uri[:host].should == host
            parsed_uri[:path].should == path
            parsed_uri[:query].should == query

            parsed_uri = described_class.fast_parse( "//#{user}:#{password}@#{host}/#{path}?#{query}" )

            parsed_uri[:scheme].should be_nil
            parsed_uri[:userinfo].should == user + ':' + password
            parsed_uri[:host].should == host
            parsed_uri[:path].should == path
            parsed_uri[:query].should == query
        end

        it 'returns a frozen hash (with frozen values)' do
            h = described_class.fast_parse( 'http://test.com/stuff/' )

            expect { h[:stuff] = 0 }.to raise_error
            expect { h[:path] << '/' }.to raise_error
        end

        it 'ignores javascript: URLs' do
            described_class.fast_parse( 'javascript:stuff()' ).should be_nil
        end
    end

    describe '.to_absolute' do
        it 'converts a relative path to absolute using the reference URL' do
            abs  = 'http://test.com/blah/ha'
            rel  = '/test'
            rel2 = 'test2'
            described_class.to_absolute( rel, abs ).should == "http://test.com" + rel
            described_class.to_absolute( rel2, abs ).should == "http://test.com/blah/" + rel2
            described_class.to_absolute( rel2, abs + '/' ).should == "http://test.com/blah/ha/" + rel2

            rel = '//domain-name.com/stuff'
            described_class.to_absolute( rel, abs ).should == "http:" + rel
        end
    end

    describe '.normalize' do
        it 'cleans the URL' do
            @urls.each do |url|
                described_class.normalize( url ).should == @ref_normalizer.call( url )
            end
            with_whitespace = 'http://test.com/stuff '
            described_class.normalize( with_whitespace ).to_s.should == with_whitespace.strip
        end
    end

    describe '.full_and_absolute?' do
        context 'when given a nil URL' do
            it 'returns false' do
                described_class.full_and_absolute?( nil ).should be_false
            end
        end

        context 'when given an non absolute URL' do
            it 'returns false' do
                described_class.full_and_absolute?( '433' ).should be_false
            end
        end

        context 'when given an absolute URL' do
            it 'returns true' do
                described_class.full_and_absolute?( 'http://stuff/' ).should be_true
            end
        end
    end

    describe '#initialize' do
        context String do
            it 'normalizes and parse the string' do
                @urls.each do |url|
                    uri = described_class.new( url )
                    uri.is_a?( Arachni::URI ).should be_true
                    uri.to_s.should == @ref_normalizer.call( url )
                end
            end
        end

        context Hash do
            it 'normalizes and construct a URI from a Hash of components' do
                @urls.each do |url|
                    uri = described_class.new( described_class.fast_parse( url ) )
                    uri.is_a?( Arachni::URI ).should be_true
                    uri.to_s.should == @ref_normalizer.call( url )
                end
            end
        end

        context URI do
            it 'normalizes and construct a URI from a Hash of components' do
                @urls.each do |url|
                    uri = ::URI.parse( described_class.normalize( url ) )
                    uri.is_a?( ::URI ).should be_true

                    a_uri = described_class.new( url )
                    a_uri.is_a?( Arachni::URI ).should be_true
                    a_uri.to_s.should == @ref_normalizer.call( url )
                end
            end
        end

        context Arachni::URI do
            it 'normalizes and construct a URI from a Hash of components' do
                @urls.each do |url|
                    uri = described_class.new( url )
                    a_uri = described_class.new( uri )
                    a_uri.is_a?( Arachni::URI ).should be_true
                    a_uri.should == uri
                end
            end
        end

        context 'else' do
            it 'raises a ArgumentError' do
                expect { described_class.new( [] ) }.to raise_error ArgumentError
            end
        end
    end

    describe '#==' do
        it 'converts both objects to strings and compare them' do
            @urls.each do |url|
                normalized_str = described_class.normalize( url )
                uri = ::URI.parse( normalized_str )
                uri.is_a?( ::URI ).should be_true

                a_uri = described_class.new( url )
                a_uri.is_a?( Arachni::URI ).should be_true

                a_uri.should == uri
                a_uri.should == normalized_str
                a_uri.should == a_uri
            end
        end
    end

    describe '#query=' do
        subject { described_class.new( 'http://test.com/?my=val' ) }

        it 'sets the URL query' do
            subject.query = 'my2=val2'
            subject.query.should == 'my2=val2'
        end

        context 'when given an empty string' do
            it 'removes the query' do
                subject.query = ''
                subject.query.should be_nil
            end
        end

        context 'when given nil' do
            it 'removes the query' do
                subject.query = ''
                subject.query.should be_nil
            end
        end
    end

    describe '#dup' do
        subject { described_class.new( 'http://test.com/?my=val' ) }

        it 'return a duplicate object' do
            dupped = subject.dup

            subject.should == dupped
            subject.object_id.should_not == dupped.object_id
        end
    end

    describe '#_dump' do
        it 'returns the URL as a string' do
            uri = 'http://test.com/?my=val'
            described_class.new( uri )._dump(nil).should == uri
        end
    end

    describe '._load' do
        it 'restores the original object from #_dump' do
            uri    = 'http://test.com/?my=val'
            parsed = described_class.new( uri )

            described_class._load( parsed._dump(nil) ).should == parsed
        end
    end

    describe '#to_absolute' do
        it 'converts a self to absolute using the reference URL' do
            abs  = 'http://test.com/blah/ha'
            rel  = '/test'
            rel2 = 'test2'
            described_class.parse( rel ).to_absolute( abs ).should == "http://test.com" + rel
            described_class.parse( rel2 ).to_absolute( abs ).should == "http://test.com/blah/" + rel2
            described_class.parse( rel2 ).to_absolute( abs + '/' ).should == "http://test.com/blah/ha/" + rel2
        end
    end

    describe '#up_to_path' do
        it 'returns the URL up to its path component (no resource name, query, fragment, etc)' do
            url = 'http://test.com/path/goes/here.php?query=goes&here=.!#frag'
            described_class.parse( url ).up_to_path.should == 'http://test.com/path/goes/'

            url = 'http://test.com/path/goes/here/?query=goes&here=.!#frag'
            described_class.parse( url ).up_to_path.should == 'http://test.com/path/goes/here/'

            url = 'http://test.com/path/goes/here?query=goes&here=.!#frag'
            described_class.parse( url ).up_to_path.should == 'http://test.com/path/goes/here/'

            url = 'http://test.com'
            described_class.parse( url ).up_to_path.should == 'http://test.com/'

            url = 'http://test.com/'
            described_class.parse( url ).up_to_path.should == 'http://test.com/'
        end
    end

    describe '#domain' do
        it 'removes the deepest subdomain from the host' do
            url = 'http://test.com/'
            described_class.parse( url ).domain.should == 'test.com'

            url = 'http://test/'
            described_class.parse( url ).domain.should == 'test'

            url = 'http://subdomain.test.com/'
            described_class.parse( url ).domain.should == 'test.com'

            url = 'http://deep.subdomain.test.com/'
            described_class.parse( url ).domain.should == 'subdomain.test.com'
        end

        context 'when no host is available' do
            it 'returns nil' do
                url = '/stuff/'
                described_class.parse( url ).domain.should be_nil
            end
        end
    end

    describe '#ip_address?' do
        context 'when passed a URL with' do
            context 'a domain name' do
                it 'returns false' do
                    described_class.parse( 'http://stuff.com/blah' ).ip_address?.should be_false
                end
            end

            context 'an IP address' do
                it 'returns the IP address' do
                    described_class.parse( 'http://127.0.0.1/blah/' ).ip_address?.should be_true
                end
            end
        end
    end

    describe '#without_query' do
        it 'returns the URI up to its resource component without the query' do
            expected = 'http://test.com/directory/resource.php'
            described_class.new( "#{expected}?param=1&param2=2" ).without_query.should == expected
        end
    end

    describe '#rewrite' do
        let(:url) { described_class.new( 'http://test.com/articles/some-stuff/23' ) }
        let(:rewritten) { described_class.new( 'http://test.com/articles.php?id=23' ) }

        it 'rewrites a URL based on the given rules' do
            url.rewrite( rewrite_rules ).should == rewritten
        end

        context 'when no rules are provided' do
            it "uses the ones in #{Arachni::OptionGroups::Scope}#url_rewrites" do
                Arachni::Options.scope.url_rewrites = rewrite_rules

                url.rewrite.should == rewritten
            end
        end

        context 'when no rules match' do
            let(:url) { described_class.new( 'http://blahblah/more.blah' ) }

            it 'returns a copy of self' do
                url.rewrite.should == url
                url.rewrite.object_id.should_not == url.object_id
            end
        end
    end

    describe '#resource_name' do
        context 'when there is no file name' do
            it 'returns nil' do
                described_class.new( 'http://stuff.com/' ).resource_name.should be_nil
            end
        end

        it 'returns the file name of the resource' do
            uri = 'http://test.com/direct.ory/resource.php?param=1&param2=2'
            described_class.new( uri ).resource_name.should == 'resource.php'
            described_class.new( 'http://stuff.com/test/' ).resource_name.should == 'test'
        end
    end

    describe '#resource_extension' do
        context 'when there is no extension' do
            it 'returns nil' do
                described_class.new( 'http://stuff.com/test' ).resource_extension.should be_nil
            end
        end

        context 'when there are multiple periods' do
            it 'returns the last one' do
                described_class.new( 'http://stuff.com/test.1.2' ).resource_extension.should == '2'
            end
        end

        it 'returns the extension of the resource' do
            uri = "http://test.com/direct.ory/resource.php?param=1&param2=2"
            described_class.new( uri ).resource_extension.should == 'php'
        end
    end

    describe '#mailto?' do
        context 'when the URI has a mailto scheme' do
            it 'returns true' do
                described_class.new( 'mailto:stuff@blah.com' ).mailto?.should be_true
            end
        end
        context 'when the URI does not have a mailto scheme' do
            it 'returns false' do
                described_class.new( 'blah.com' ).mailto?.should be_false
            end
        end
    end

    describe '#hash' do
        it 'returns a hash uniquely identifying the URI' do
            uri = described_class.new( 'http://stuff/' )
            uri.hash.should be_kind_of Integer
            uri.hash.should == uri.hash

            uri2 = described_class.new( 'http://stuff2/' )
            uri.hash.should_not == uri2.hash
        end

        it 'is an integer' do
            described_class.new( 'http://stuff/' ).hash.should be_kind_of Integer
        end
    end

    describe '#persistent_hash' do
        it 'returns a hash uniquely identifying the URI' do
            uri = described_class.new( 'http://stuff/' )
            uri.persistent_hash.should be_kind_of Integer
            uri.persistent_hash.should == uri.persistent_hash

            uri2 = described_class.new( 'http://stuff2/' )
            uri.persistent_hash.should_not == uri2.persistent_hash
        end

        it 'is an integer' do
            described_class.new( 'http://stuff/' ).persistent_hash.should be_kind_of Integer
        end
    end
end
