# encoding: utf-8
require_relative '../../spec_helper'

describe Arachni::Module::Utilities do

    before( :all ) do
        @opts = Arachni::Options.instance
        @utils = Arachni::Module::Utilities
    end

    describe :url_parser do
        it 'should return a URI::Parser' do
            @utils.uri_parser.class.should == URI::Parser
        end
    end

    describe :url_parse do
        it 'should parse a URI' do

            scheme = 'http'
            user = 'user'
            password = 'password'
            host = 'subdomain.domainname.tld'
            path = '/some/path'
            query = 'param=val&param2=val2'
            fragment = 'fragment'

            uri = "#{scheme}://#{user}:#{password}@#{host}#{path}?#{query}\##{fragment}"

            parsed_uri = @utils.uri_parse( uri )

            parsed_uri.class.should == URI::HTTP
            parsed_uri.to_s.should == uri

            parsed_uri.scheme.should == scheme
            parsed_uri.user.should == user
            parsed_uri.password.should == password
            parsed_uri.host.should == host
            parsed_uri.path.should == path
            parsed_uri.query.should == query
            parsed_uri.fragment.should == fragment
        end
    end

    describe :url_decode do
        it 'should decode a URI' do
            uri = 'my%20test.asp?name=st%C3%A5le&car=saab'
            @utils.uri_decode( uri ).should == "my test.asp?name=ståle&car=saab"
        end
    end

    describe :url_sanitize do
        it 'should iteratively decode a uri' do
            uri = "my test.asp?name=ståle&car=saab"
            multi = sanitized = @utils.uri_encode( uri )

            3.times { multi = @utils.uri_encode( multi ) }

            @utils.url_sanitize( multi ).should == sanitized
        end
    end

    describe :to_absolute do
        it 'should convert a relative path to absolute' do
            @opts.url  = 'http://test2.com/blah/ha'
            rel  = '/test'
            rel2 = 'test2'
            @utils.to_absolute( rel ).should == "http://test2.com" + rel
            @utils.to_absolute( rel2 ).should == "http://test2.com/blah/" + rel2
        end

        context 'when called with a 2nd parameter' do
            it 'should use it as a reference for the conversion' do
                abs  = 'http://test.com/blah/ha'
                rel  = '/test'
                rel2 = 'test2'
                @utils.to_absolute( rel, abs ).should == "http://test.com" + rel
                @utils.to_absolute( rel2, abs ).should == "http://test.com/blah/" + rel2
                @utils.to_absolute( rel2, abs + '/' ).should == "http://test.com/blah/ha/" + rel2
            end
        end
    end

    describe :path_in_domain? do
        before { @opts.url = 'http://bar.com' }

        context 'when a second argument (reference URL) is provided' do
            context 'with a path that is in the domain' do
                it 'should return true' do
                    @utils.path_in_domain?( 'http://yes.com/foo', 'http://yes.com' ).should be_true
                end
            end
            context 'with a path that is outside the domain' do
                it 'should return true' do
                    @utils.path_in_domain?( 'http://no.com/foo', 'http://yes.com' ).should be_false
                end
            end
        end

        context 'when follow subdomains is disabled' do
            before { @opts.follow_subdomains = false }

            context 'with a URL with a different domain' do
                it 'should return false' do
                    @utils.path_in_domain?( 'http://google.com' ).should be_false
                    @utils.skip_path?( 'http://google.com' ).should be_true
                end
            end

            context 'with a URL with the same domain' do
                it 'should return true' do
                    @utils.path_in_domain?( 'http://bar.com/test/' ).should be_true
                    @utils.skip_path?( 'http://bar.com/test/' ).should be_false
                end
            end


            context 'with a URL with a different subdomain' do
                it 'should return false' do
                    @utils.path_in_domain?( 'http://test.bar.com/test' ).should be_false
                    @utils.skip_path?( 'http://test.bar.com/test' ).should be_true
                end
            end
        end

        context 'when follow subdomains is disabled' do
            before { @opts.follow_subdomains = true }

            context 'with a URL with a different domain' do
                it 'should return false' do
                    @utils.path_in_domain?( 'http://google.com' ).should be_false
                    @utils.skip_path?( 'http://google.com' ).should be_true
                end
            end

            context 'with a URL with the same domain' do
                it 'should return true' do
                    @utils.path_in_domain?( 'http://bar.com/test/' ).should be_true
                    @utils.skip_path?( 'http://bar.com/test/' ).should be_false
                end
            end


            context 'with a URL with a different subdomain' do
                it 'should return true' do
                    @utils.path_in_domain?( 'http://test.bar.com/test' ).should be_true
                    @utils.skip_path?( 'http://test.bar.com/test' ).should be_false
                end
            end
        end
    end

    describe :exclude_path? do
        before { @opts.exclude << /skip_me/ }

        context 'when a path matches an exclude rule' do
            it 'should return true' do
                @utils.exclude_path?( 'skip_me' ).should be_true
                @utils.skip_path?( 'http://bar.com/skip_me' ).should be_true
            end
        end

        context 'when a path does not match an exclude rule' do
            it 'should return false' do
                @utils.exclude_path?( 'not_me' ).should be_false
                @utils.skip_path?( 'http://bar.com/not_me' ).should be_false
            end
        end
    end

    describe :include_path? do
        before { @opts.include << /include_me/ }

        context 'when a path matches an include rule' do
            it 'should return true' do
                @utils.include_path?( 'include_me' ).should be_true
                @utils.skip_path?( 'http://bar.com/include_me' ).should be_false
            end
        end

        context 'when a path does not match an include rule' do
            it 'should return false' do
                @utils.include_path?( 'not_me' ).should be_false
                @utils.skip_path?( 'http://bar.com/not_me' ).should be_true
            end
        end
    end


    describe :get_path do
        context 'when the url only has a path' do
            it 'should not change it' do
                uri_with_path = 'http://test.com/some/path/'
                @utils.get_path( uri_with_path ).should == uri_with_path
            end
        end

        context 'when the url only has a path without a terminating slash' do
            it 'should append a slash to it' do
                uri_with_path = 'http://test.com/some/path'
                @utils.get_path( uri_with_path ).should == uri_with_path + '/'
            end
        end

        context 'when the url has elements past its path' do
            context 'with a slash after its path' do
                it 'should only return it up to its path with a terminating slash' do
                    uri = 'http://test.com/some/path/'
                    uri2 = uri + '?query=val&var=val2#frag'
                    @utils.get_path( uri2 ).should == uri
                end
            end

            context 'with aout slash after its path' do
                it 'should only return it up to its path with a terminating slash' do
                    uri = 'http://test.com/some/path'
                    uri2 = uri + '?query=val&var=val2#frag'
                    @utils.get_path( uri2 ).should == uri + '/'
                end
            end
        end
    end

    describe :seed do
        it 'should return a random string' do
            @utils.seed.class.should == String
        end
    end

    describe :normalize_url do
        it 'should clean the URL' do
            uri = %w{http://ba.com/%$35453464634\ [][4\'4]5454$%%43576876879'["{|['[.l?;]]}"]'?var=val\!~`1#dcddrtrtr%&65&46576\ 6'7\ 6'\ '/'}.first
            begin
                normalized = @utils.normalize_url( uri )
                @utils.uri_parse( normalized ).to_s
                true.should be_true
            rescue
                false.should be_true
            end
        end
    end

    describe :read_file do
        it 'should read a file from a directory with the same name as the caller one line at a time' do

            filename = 'read_file.txt'
            filepath = File.expand_path( File.dirname( __FILE__ ) ) + '/utilities_spec/' + filename

            lines = []
            @utils.read_file( filename ){
                |line|
                lines << line
            }

            lines.join( "\n" ).should == IO.read( filepath ).strip
        end
    end

    describe :hash_keys_to_str do
        it 'should recursively convert a Hash\'s keys to strings' do
            h1 = {
                key1: 'val1',
                hash: {
                    lvl2: 'val2',
                }
            }

            h2 = {
                'key1' => 'val1',
                'hash' => {
                    'lvl2' => 'val2',
                }
            }

            @utils.hash_keys_to_str( h1 ).should == h2
        end
    end

    describe :exception_jail do
        context 'when raise_exception = true' do
            it 'should forward exceptions' do
                begin
                    @utils.exception_jail( true ) {
                        raise 'Exception!'
                    }
                    false.should be_true
                rescue RuntimeError => e
                    true.should be_true
                end
            end
        end

        context 'when raise_exception = false' do
            it 'should discard exceptions' do
                begin
                    @utils.exception_jail( false ) {
                        raise 'Exception!'
                    }
                    true.should be_true
                rescue RuntimeError => e
                    false.should be_true
                end
            end
        end
    end

end
