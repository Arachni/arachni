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
            'http://stuff.host.fdfd/web/seguros/auto;jsessionid=6CB5A6A4597FFFA80C4D23B235072588.000?test=tet',
            'http://127.0.0.2:51453/link-template/append/input/default%23%5E($!@$)(()))******/stuff'
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
               "http://testfire.net/bank/queryxpath.aspx?__EVENTVALIDATION=/wEWAwLNx%202YBwKw59eKCgKcjoPABw==&__VIEWSTATE=/wEPDwUKMTEzMDczNTAxOWRk&_ctl0:_ctl0:Content:Main:Button1=Query&_ctl0:_ctl0:Content:Main:TextBox1=Enter%20title%20(e.g.%20IBM)';echo%20287630581954%204196403186331128;%23",
           "http://192.168.0.232/dvwa/phpinfo.php?=PHPB8B5F2A0-3C92-11d3-A3A9-4C7B08C10000%23%5E%28%24%21%40%24%29%28%28%29%29%29%2A%2A%2A%2A%2A%2A&_arachni_trainer_c987fdb6d3955bd60191449bc465bb5ca760f60661fa4bcdf28736ae04aa2a1e=c987fdb6d3955bd60191449bc465bb5ca760f60661fa4bcdf28736ae04aa2a1e"=>
               "http://192.168.0.232/dvwa/phpinfo.php?=PHPB8B5F2A0-3C92-11d3-A3A9-4C7B08C10000%23%5E($!@$)(()))******&_arachni_trainer_c987fdb6d3955bd60191449bc465bb5ca760f60661fa4bcdf28736ae04aa2a1e=c987fdb6d3955bd60191449bc465bb5ca760f60661fa4bcdf28736ae04aa2a1e",
           "http://foo.com/user/login?user%5Bname%5D=bar&user%5Bpass%5D=asdasd%26asdihbasd"=>
               "http://foo.com/user/login?user%5Bname%5D=bar&user%5Bpass%5D=asdasd%26asdihbasd",
           "http://stuff.host.fdfd/web/seguros/auto;jsessionid=6CB5A6A4597FFFA80C4D23B235072588.000?test=tet"=>
               "http://stuff.host.fdfd/web/seguros/auto?test=tet",
            'http://127.0.0.2:51453/link-template/append/input/default%23%5E($!@$)(()))******/stuff' =>
                'http://127.0.0.2:51453/link-template/append/input/default%23%5E($!@$)(()))******/stuff'
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
                expect(uri.is_a?( Arachni::URI )).to be_truthy
                expect(uri.to_s).to eq(@ref_normalizer.call( url ))
            end
        end
    end

    describe '.rewrite' do
        let(:url) { 'http://test.com/articles/some-stuff/23' }

        it 'rewrites a URL based on the given rules' do
            expect(described_class.rewrite( url, rewrite_rules )).to eq(
                'http://test.com/articles.php?id=23'
            )
        end

        context 'when no rules are provided' do
            it "uses the ones in #{Arachni::OptionGroups::Scope}#url_rewrites" do
                Arachni::Options.scope.url_rewrites = rewrite_rules

                expect(described_class.rewrite( url )).to eq(
                    'http://test.com/articles.php?id=23'
                )
            end
        end
    end

    describe '.parse_query' do
        it 'returns the query parameters as a Hash' do
            url = 'http://test/?param_one=value_one&param_two=value_two'
            expect(described_class.parse_query( url )).to eq({
                'param_one' => 'value_one',
                'param_two' => 'value_two'
            })
        end

        it 'decodes the parameters' do
            url = 'http://test/?stuff%20here=bl%20ah'
            expect(described_class.parse_query( url )).to eq({
                'stuff here' => 'bl ah'
            })
        end

        context 'when passed' do
            describe 'nil' do
                it 'returns an empty Hash' do
                    expect(described_class.parse_query( nil )).to eq({})
                end
            end
            describe 'an unparsable URL' do
                it 'returns an empty Hash' do
                    url = '$#%^$6#5436#$%^'
                    expect(described_class.parse_query( url )).to eq({})
                end
            end
        end
    end

    describe '.encode' do
        it 'decodes a URI' do
            uri = "my test.asp?name=ståle&car=saab"
            expect(described_class.encode( uri )).to eq('my%20test.asp?name=st%C3%A5le&car=saab')
        end
    end

    describe '.decode' do
        it 'decodes a URI' do
            uri = 'my%20test.asp?name=st%C3%A5le&car=saab'
            expect(described_class.decode( uri )).to eq("my test.asp?name=ståle&car=saab")
        end
    end

    describe '.parser' do
        it 'returns a URI::Parser' do
            expect(described_class.parser.class).to eq(::URI::Parser)
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

            expect(parsed_uri.to_s).to eq(uri)

            expect(parsed_uri.scheme).to eq(scheme)
            expect(parsed_uri.user).to eq(user)
            expect(parsed_uri.password).to eq(password)
            expect(parsed_uri.host).to eq(host)
            expect(parsed_uri.path).to eq(path)
            expect(parsed_uri.query).to eq(query)
        end

        it 'ignores javascript: URLs' do
            expect(described_class.parse( 'javascript:stuff()' )).to be_nil
            expect(described_class.parse( 'jAvaScRipT:stuff()' )).to be_nil
        end

        it 'ignores data: URLs' do
            expect(described_class.parse( 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA
AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO
9TXL0Y4OHwAAAABJRU5ErkJggg==' )).to be_nil

            expect(described_class.parse( 'dAtA:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA
AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO
9TXL0Y4OHwAAAABJRU5ErkJggg==' )).to be_nil
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

            expect(parsed_uri[:scheme]).to eq(scheme)
            expect(parsed_uri[:userinfo]).to eq(user + ':' + password)
            expect(parsed_uri[:host]).to eq(host)
            expect(parsed_uri[:path]).to eq(path)
            expect(parsed_uri[:query]).to eq(query)

            parsed_uri = described_class.fast_parse( "//#{user}:#{password}@#{host}/#{path}?#{query}" )

            expect(parsed_uri[:scheme]).to be_nil
            expect(parsed_uri[:userinfo]).to eq(user + ':' + password)
            expect(parsed_uri[:host]).to eq(host)
            expect(parsed_uri[:path]).to eq(path)
            expect(parsed_uri[:query]).to eq(query)
        end

        it 'ignores javascript: URLs' do
            expect(described_class.fast_parse( 'javascript:stuff()' )).to be_nil
        end

        it 'ignores fragment-only URLs' do
            expect(described_class.fast_parse( '#/stuff/here?blah=1' )).to be_nil
        end
    end

    describe '.to_absolute' do
        let(:reference) do
            'http://test.com/blah/ha?name=val#/!/stuff/?fname=fval'
        end
        let(:sanitized_reference) do
            'http://test.com/blah/ha?name=val'
        end

        it 'converts a relative path to absolute using the reference URL' do
            abs  = reference

            expect(described_class.to_absolute( '', abs )).to eq('http://test.com/blah/ha?name=val')

            rel  = '/test'
            expect(described_class.to_absolute( rel, abs )).to eq('http://test.com/test')

            rel  = '/test?name2=val2'
            expect(described_class.to_absolute( rel, abs )).to eq('http://test.com/test?name2=val2')

            rel  = '?name2=val2'
            expect(described_class.to_absolute( rel, abs )).to eq('http://test.com/blah/ha?name2=val2')

            rel2 = 'test2'
            expect(described_class.to_absolute( rel2, abs )).to eq('http://test.com/blah/test2')

            abs  = 'http://test.com/blah/ha/?name=val#/!/stuff/?fname=fval'
            expect(described_class.to_absolute( rel2, abs )).to eq('http://test.com/blah/ha/test2')

            rel = '//domain-name.com/stuff'
            expect(described_class.to_absolute( rel, abs )).to eq('http://domain-name.com/stuff')

            rel = '//domain-name.com'
            expect(described_class.to_absolute( rel, abs )).to eq('http://domain-name.com/')
        end

        context 'when the URL starts with javascript:' do
            it 'returns the sanitized reference URL' do
                rel = 'javascript:stuff()'
                expect(described_class.to_absolute( rel, reference )).to eq(sanitized_reference)
            end
        end

        context 'when the URL only has fragment data' do
            it 'returns the sanitized reference URL' do
                rel = '#/stuff/here?blah=1'
                expect(described_class.to_absolute( rel, reference )).to eq(sanitized_reference)
            end
        end
    end

    describe '.normalize' do
        it 'cleans the URL' do
            @urls.each do |url|
                expect(described_class.normalize( url )).to eq(@ref_normalizer.call( url ))
            end
            with_whitespace = 'http://test.com/stuff '
            expect(described_class.normalize( with_whitespace ).to_s).to eq(with_whitespace.strip)
        end
    end

    describe '.full_and_absolute?' do
        context 'when given a nil URL' do
            it 'returns false' do
                expect(described_class.full_and_absolute?( nil )).to be_falsey
            end
        end

        context 'when given an non absolute URL' do
            it 'returns false' do
                expect(described_class.full_and_absolute?( '433' )).to be_falsey
            end
        end

        context 'when given an absolute URL' do
            it 'returns true' do
                expect(described_class.full_and_absolute?( 'http://stuff/' )).to be_truthy
            end
        end
    end

    describe '#initialize' do
        it 'normalizes and parses the string' do
            @urls.each do |url|
                uri = described_class.new( url )
                expect(uri.is_a?( Arachni::URI )).to be_truthy
                expect(uri.to_s).to eq(@ref_normalizer.call( url ))
            end
        end
    end

    describe '#==' do
        it 'converts both objects to strings and compare them' do
            @urls.each do |url|
                normalized_str = described_class.normalize( url )

                a_uri = described_class.new( url )
                expect(a_uri.is_a?( Arachni::URI )).to be_truthy

                expect(a_uri).to eq(normalized_str)
                expect(a_uri).to eq(a_uri)
            end
        end
    end

    describe '#seed_in_host?' do
        let(:parsed) { described_class.new( url ) }

        context 'when the seed is in the domain' do
            let(:url) { "http://www.#{Arachni::Utilities.random_seed}.com/stuff" }

            it 'returns true' do
                expect(parsed.seed_in_host?).to be_truthy
            end
        end

        context 'when the seed is in the subdomain' do
            let(:url) { "http://#{Arachni::Utilities.random_seed}.test.com" }

            it 'returns true' do
                expect(parsed.seed_in_host?).to be_truthy
            end
        end

        context 'when the seed is in the TLD' do
            let(:url) { "http://test.#{Arachni::Utilities.random_seed}" }

            it 'returns true' do
                expect(parsed.seed_in_host?).to be_truthy
            end
        end

        context 'when the seed is not in the host' do
            let(:url) { "http://test.com" }

            it 'returns false' do
                expect(parsed.seed_in_host?).to be_falsey
            end
        end
    end

    describe '#relative?'
    describe '#absolute?'

    describe '#query=' do
        subject { described_class.new( 'http://test.com/?my=val' ) }

        it 'sets the URL query' do
            subject.query = 'my2=val2'
            expect(subject.query).to eq('my2=val2')
        end

        context 'when given an empty string' do
            it 'removes the query' do
                subject.query = ''
                expect(subject.query).to be_nil
            end
        end

        context 'when given nil' do
            it 'removes the query' do
                subject.query = ''
                expect(subject.query).to be_nil
            end
        end
    end

    describe '#dup' do
        subject { described_class.new( 'http://test.com/?my=val' ) }

        it 'return a duplicate object' do
            dupped = subject.dup

            expect(subject).to eq(dupped)
            expect(subject.object_id).not_to eq(dupped.object_id)
        end
    end

    describe '#_dump' do
        it 'returns the URL as a string' do
            uri = 'http://test.com/?my=val'
            expect(described_class.new( uri )._dump(nil)).to eq(uri)
        end
    end

    describe '._load' do
        it 'restores the original object from #_dump' do
            uri    = 'http://test.com/?my=val'
            parsed = described_class.new( uri )

            expect(described_class._load( parsed._dump(nil) )).to eq(parsed)
        end
    end

    describe '#to_absolute' do
        it 'converts a self to absolute using the reference URL' do
            abs  = 'http://test.com/blah/ha'
            rel  = '/test'
            rel2 = 'test2'
            expect(described_class.parse( rel ).to_absolute( abs )).to eq("http://test.com" + rel)
            expect(described_class.parse( rel2 ).to_absolute( abs )).to eq("http://test.com/blah/" + rel2)
            expect(described_class.parse( rel2 ).to_absolute( abs + '/' )).to eq("http://test.com/blah/ha/" + rel2)
        end
    end

    describe '#up_to_path' do
        it 'returns the URL up to its path component (no resource name, query, fragment, etc)' do
            url = 'http://test.com/path/goes/here.php?query=goes&here=.!#frag'
            expect(described_class.parse( url ).up_to_path).to eq('http://test.com/path/goes/')

            url = 'http://test.com/path/goes/here/?query=goes&here=.!#frag'
            expect(described_class.parse( url ).up_to_path).to eq('http://test.com/path/goes/here/')

            url = 'http://test.com/path/goes/here?query=goes&here=.!#frag'
            expect(described_class.parse( url ).up_to_path).to eq('http://test.com/path/goes/here/')

            url = 'http://test.com'
            expect(described_class.parse( url ).up_to_path).to eq('http://test.com/')

            url = 'http://test.com/'
            expect(described_class.parse( url ).up_to_path).to eq('http://test.com/')
        end
    end

    describe '#up_to_port' do
        it 'returns the URL up to its port' do
            url = 'http://test.com/path/goes/here.php?query=goes&here=.!#frag'
            expect(described_class.parse( url ).up_to_port).to eq('http://test.com')

            url = 'http://test.com:80/path/goes/here/?query=goes&here=.!#frag'
            expect(described_class.parse( url ).up_to_port).to eq('http://test.com')

            url = 'http://test.com:23/path/goes/here?query=goes&here=.!#frag'
            expect(described_class.parse( url ).up_to_port).to eq('http://test.com:23')

            url = 'https://test.com:443/'
            expect(described_class.parse( url ).up_to_port).to eq('https://test.com')

            url = 'https://test.com:54/'
            expect(described_class.parse( url ).up_to_port).to eq('https://test.com:54')
        end
    end

    describe '#domain' do
        it 'removes the deepest subdomain from the host' do
            url = 'http://test.com/'
            expect(described_class.parse( url ).domain).to eq('test.com')

            url = 'http://test/'
            expect(described_class.parse( url ).domain).to eq('test')

            url = 'http://subdomain.test.com/'
            expect(described_class.parse( url ).domain).to eq('test.com')

            url = 'http://deep.subdomain.test.com/'
            expect(described_class.parse( url ).domain).to eq('subdomain.test.com')
        end

        context 'when no host is available' do
            it 'returns nil' do
                url = '/stuff/'
                expect(described_class.parse( url ).domain).to be_nil
            end
        end
    end

    describe '#ip_address?' do
        context 'when passed a URL with' do
            context 'a domain name' do
                it 'returns false' do
                    expect(described_class.parse( 'http://stuff.com/blah' ).ip_address?).to be_falsey
                end
            end

            context 'an IP address' do
                it 'returns the IP address' do
                    expect(described_class.parse( 'http://127.0.0.1/blah/' ).ip_address?).to be_truthy
                end
            end
        end
    end

    describe '#without_query' do
        it 'returns the URI up to its resource component without the query' do
            expected = 'http://test.com/directory/resource.php'
            expect(described_class.new( "#{expected}?param=1&param2=2" ).without_query).to eq(expected)
        end
    end

    describe '#rewrite' do
        let(:url) { described_class.new( 'http://test.com/articles/some-stuff/23' ) }
        let(:rewritten) { described_class.new( 'http://test.com/articles.php?id=23' ) }

        it 'rewrites a URL based on the given rules' do
            expect(url.rewrite( rewrite_rules )).to eq(rewritten)
        end

        context 'when no rules are provided' do
            it "uses the ones in #{Arachni::OptionGroups::Scope}#url_rewrites" do
                Arachni::Options.scope.url_rewrites = rewrite_rules

                expect(url.rewrite).to eq(rewritten)
            end
        end

        context 'when no rules match' do
            let(:url) { described_class.new( 'http://blahblah/more.blah' ) }

            it 'returns a copy of self' do
                expect(url.rewrite).to eq(url)
                expect(url.rewrite.object_id).not_to eq(url.object_id)
            end
        end
    end

    describe '#resource_name' do
        context 'when there is no file name' do
            it 'returns nil' do
                expect(described_class.new( 'http://stuff.com/' ).resource_name).to be_nil
            end
        end

        it 'returns the file name of the resource' do
            uri = 'http://test.com/direct.ory/resource.php?param=1&param2=2'
            expect(described_class.new( uri ).resource_name).to eq('resource.php')
            expect(described_class.new( 'http://stuff.com/test/' ).resource_name).to eq('test')
        end
    end

    describe '#resource_extension' do
        context 'when there is no extension' do
            it 'returns nil' do
                expect(described_class.new( 'http://stuff.com/test' ).resource_extension).to be_nil
            end
        end

        context 'when there are multiple periods' do
            it 'returns the last one' do
                expect(described_class.new( 'http://stuff.com/test.1.2' ).resource_extension).to eq('2')
            end
        end

        it 'returns the extension of the resource' do
            uri = "http://test.com/direct.ory/resource.php?param=1&param2=2"
            expect(described_class.new( uri ).resource_extension).to eq('php')
        end
    end

    describe '#hash' do
        it 'returns a hash uniquely identifying the URI' do
            uri = described_class.new( 'http://stuff/' )
            expect(uri.hash).to be_kind_of Integer
            expect(uri.hash).to eq(uri.hash)

            uri2 = described_class.new( 'http://stuff2/' )
            expect(uri.hash).not_to eq(uri2.hash)
        end

        it 'is an integer' do
            expect(described_class.new( 'http://stuff/' ).hash).to be_kind_of Integer
        end
    end

    describe '#persistent_hash' do
        it 'returns a hash uniquely identifying the URI' do
            uri = described_class.new( 'http://stuff/' )
            expect(uri.persistent_hash).to be_kind_of Integer
            expect(uri.persistent_hash).to eq(uri.persistent_hash)

            uri2 = described_class.new( 'http://stuff2/' )
            expect(uri.persistent_hash).not_to eq(uri2.persistent_hash)
        end

        it 'is an integer' do
            expect(described_class.new( 'http://stuff/' ).persistent_hash).to be_kind_of Integer
        end
    end
end
