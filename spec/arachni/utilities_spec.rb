# encoding: utf-8
require 'spec_helper'

describe Arachni::Utilities do

    before( :each ) do
        @opts = Arachni::Options.reset
        @utils = Arachni::Module::Utilities
    end

    describe '#uri_parser' do
        it 'returns a URI::Parser' do
            @utils.uri_parser.class.should == ::URI::Parser
        end
    end

    describe '#uri_parse' do
        it 'parses a URI' do

            scheme   = 'http'
            user     = 'user'
            password = 'password'
            host     = 'subdomain.domainname.tld'
            path     = '/some/path'
            query    = 'param=val&param2=val2'

            uri = "#{scheme}://#{user}:#{password}@#{host}#{path}?#{query}"

            parsed_uri = @utils.uri_parse( uri )

            parsed_uri.to_s.should == uri

            parsed_uri.scheme.should == scheme
            parsed_uri.user.should == user
            parsed_uri.password.should == password
            parsed_uri.host.should == host
            parsed_uri.path.should == path
            parsed_uri.query.should == query
        end
    end

    describe '#uri_decode' do
        it 'decodes a URI' do
            uri = 'my%20test.asp?name=st%C3%A5le&car=saab'
            @utils.uri_decode( uri ).should == "my test.asp?name=ståle&car=saab"
        end
    end

    describe '#to_absolute' do
        it 'converts a relative path to absolute' do
            @opts.url  = 'http://test2.com/blah/ha'
            rel  = '/test'
            rel2 = 'test2'
            @utils.to_absolute( rel ).should == "http://test2.com" + rel
            @utils.to_absolute( rel2 ).should == "http://test2.com/blah/" + rel2
        end

        context 'when called with a 2nd parameter' do
            it 'uses it as a reference for the conversion' do
                abs  = 'http://test.com/blah/ha'
                rel  = '/test'
                rel2 = 'test2'
                @utils.to_absolute( rel, abs ).should == "http://test.com" + rel
                @utils.to_absolute( rel2, abs ).should == "http://test.com/blah/" + rel2
                @utils.to_absolute( rel2, abs + '/' ).should == "http://test.com/blah/ha/" + rel2
            end
        end
    end

    describe '#redundant_path?' do
        context "when a URL's counter reaches 0" do
            it 'returns true' do
                Arachni::Options.redundant = { /match_this/ => 10 }

                url = 'http://stuff.com/match_this'
                10.times do
                    @utils.redundant_path?( url ).should be_false
                end

                @utils.redundant_path?( url ).should be_true
            end
        end
        context "when a URL's counter has not reached 0" do
            it 'returns false' do
                Arachni::Options.redundant = { /match_this/ => 11 }

                url = 'http://stuff.com/match_this'
                10.times do
                    @utils.redundant_path?( url ).should be_false
                end

                @utils.redundant_path?( url ).should be_false
            end
        end
    end

    describe '#path_in_domain?' do
        before { @opts.url = 'http://bar.com' }

        context 'when a second argument (reference URL) is provided' do
            context 'with a path that is in the domain' do
                it 'returns true' do
                    @utils.path_in_domain?( 'http://yes.com/foo', 'http://yes.com' ).should be_true
                end
            end
            context 'with a path that is outside the domain' do
                it 'returns true' do
                    @utils.path_in_domain?( 'http://no.com/foo', 'http://yes.com' ).should be_false
                end
            end
        end

        context 'when follow subdomains is disabled' do
            before { @opts.follow_subdomains = false }

            context 'with a URL with a different domain' do
                it 'returns false' do
                    @utils.path_in_domain?( 'http://google.com' ).should be_false
                    @utils.skip_path?( 'http://google.com' ).should be_true
                end
            end

            context 'with a URL with the same domain' do
                it 'returns true' do
                    @utils.path_in_domain?( 'http://bar.com/test/' ).should be_true
                    @utils.skip_path?( 'http://bar.com/test/' ).should be_false
                end
            end


            context 'with a URL with a different subdomain' do
                it 'returns false' do
                    @utils.path_in_domain?( 'http://test.bar.com/test' ).should be_false
                    @utils.skip_path?( 'http://test.bar.com/test' ).should be_true
                end
            end
        end

        context 'when follow subdomains is disabled' do
            before { @opts.follow_subdomains = true }

            context 'with a URL with a different domain' do
                it 'returns false' do
                    @utils.path_in_domain?( 'http://google.com' ).should be_false
                    @utils.skip_path?( 'http://google.com' ).should be_true
                end
            end

            context 'with a URL with the same domain' do
                it 'returns true' do
                    @utils.path_in_domain?( 'http://bar.com/test/' ).should be_true
                    @utils.skip_path?( 'http://bar.com/test/' ).should be_false
                end
            end


            context 'with a URL with a different subdomain' do
                it 'returns true' do
                    @utils.path_in_domain?( 'http://test.bar.com/test' ).should be_true
                    @utils.skip_path?( 'http://test.bar.com/test' ).should be_false
                end
            end
        end
    end

    describe '#exclude_path?' do
        before { @opts.exclude << /skip_me/ }

        context 'when a path matches an exclude rule' do
            it 'returns true' do
                @utils.exclude_path?( 'skip_me' ).should be_true
                @utils.skip_path?( 'http://bar.com/skip_me' ).should be_true
            end
        end

        context 'when a path does not match an exclude rule' do
            it 'returns false' do
                @utils.exclude_path?( 'not_me' ).should be_false
                @utils.skip_path?( 'http://bar.com/not_me' ).should be_false
            end
        end
    end

    describe '#ignore_page?' do
        before { @opts.exclude_pages << /ignore me/ }

        context 'when the body matches an ignore rule' do
            it 'returns true' do
                page = Arachni::Page.from_data( url: 'http://test/', body: 'ignore me' )
                @utils.skip_page?( page ).should be_true
            end
        end

        context 'when the body does not match an ignore rule' do
            it 'returns false' do
                page = Arachni::Page.from_data(
                    url: 'http://test/',
                    body: 'not me'
                )
                @utils.skip_page?( page ).should be_false
            end
        end
    end

    describe '#ignore_response?' do
        before { @opts.exclude_pages << /ignore me/ }

        context 'when the body matches an ignore rule' do
            it 'returns true' do
                res = Arachni::HTTP::Response.new( body: 'ignore me' )
                @utils.skip_response?( res ).should be_true
            end
        end

        context 'when the body does not match an ignore rule' do
            it 'returns false' do
                res = Arachni::HTTP::Response.new(
                    url: 'http://test/',
                    body: 'not me'
                )
                @utils.skip_response?( res ).should be_false
            end
        end
    end

    describe '#include_path?' do
        before { @opts.include << /include_me/ }

        context 'when a path matches an include rule' do
            it 'returns true' do
                @utils.include_path?( 'include_me' ).should be_true
                @utils.skip_path?( 'http://bar.com/include_me' ).should be_false
            end
        end

        context 'when a path does not match an include rule' do
            it 'returns false' do
                @utils.include_path?( 'not_me' ).should be_false
                @utils.skip_path?( 'http://bar.com/not_me' ).should be_true
            end
        end
    end

    describe '#skip_resource?' do
        before do
            @opts.exclude_pages << /ignore\s+me/m
            @opts.exclude << /ignore/
        end

        context 'when passed a' do
            context Arachni::HTTP::Response do

                context 'whose body matches an ignore rule' do
                    it 'returns true' do
                        res = Arachni::HTTP::Response.new(
                            url: 'http://stuff/here',
                            body: 'ignore me'
                        )
                        @utils.skip_resource?( res ).should be_true
                    end
                end

                context 'whose the body does not match an ignore rule' do
                    it 'returns false' do
                        res = Arachni::HTTP::Response.new(
                            url: 'http://stuff/here',
                            body: 'stuff'
                        )
                        @utils.skip_resource?( res ).should be_false
                    end
                end

                context 'whose URL matches an exclude rule' do
                    it 'returns true' do
                        res = Arachni::HTTP::Response.new(
                            url: 'http://stuff/here/to/ignore/',
                            body: 'ignore me'
                        )
                        @utils.skip_resource?( res ).should be_true
                    end
                end

                context 'whose URL does not match an exclude rule' do
                    it 'returns false' do
                        res = Arachni::HTTP::Response.new(
                            url: 'http://stuff/here',
                            body: 'stuff'
                        )
                        @utils.skip_resource?( res ).should be_false
                    end
                end
            end

            context Arachni::Page do
                context 'whose the body matches an ignore rule' do
                    it 'returns true' do
                        page = Arachni::Page.from_data(
                            url:   'http://stuff/here',
                            body: 'ignore me'
                        )
                        @utils.skip_resource?( page ).should be_true
                    end
                end

                context 'whose the body does not match an ignore rule' do
                    it 'returns false' do
                        page = Arachni::Page.from_data(
                            url:   'http://stuff/here',
                            body: 'stuff'
                        )
                        @utils.skip_resource?( page ).should be_false
                    end
                end

                context 'whose URL matches an exclude rule' do
                    it 'returns true' do
                        res = Arachni::Page.from_data(
                            url:   'http://stuff/here/to/ignore/',
                            body: 'ignore me'
                        )
                        @utils.skip_resource?( res ).should be_true
                    end
                end

                context 'whose URL does not match an exclude rule' do
                    it 'returns false' do
                        res = Arachni::Page.from_data(
                            url:  'http://stuff/here',
                            body: 'stuff'
                        )
                        @utils.skip_resource?( res ).should be_false
                    end
                end

            end

            context String do
                context 'with multiple lines' do
                    context 'which matches an ignore rule' do
                        it 'returns true' do
                            s = "ignore \n me"
                            @utils.skip_resource?( s ).should be_true
                        end
                    end

                    context 'which does not match an ignore rule' do
                        it 'returns false' do
                            s = "multi \n line \n stuff here"
                            @utils.skip_resource?( s ).should be_false
                        end
                    end
                end

                context 'with a single line' do
                    context 'which matches an exclude rule' do
                        it 'returns true' do
                            s = "ignore/this/path"
                            @utils.skip_resource?( s ).should be_true
                        end
                    end

                    context 'which does not match an exclude rule' do
                        it 'returns false' do
                            s = "stuf/here/"
                            @utils.skip_resource?( s ).should be_false
                        end
                    end

                end
            end
        end
    end

    describe '#follow_protocol?' do
        context 'when the scheme is' do
            context 'HTTP' do
                it 'returns true' do
                    @opts.url = 'https://test2.com/blah/ha'
                    @opts.https_only = true

                    url = 'https://test2.com/blah/ha'

                    @utils.follow_protocol?( url ).should be_true
                    @utils.skip_path?( url ).should be_false
                end
            end
            context 'HTTPS' do
                it 'returns true' do
                    @opts.url = 'https://test2.com/blah/ha'
                    @opts.https_only = true

                    url = 'https://test2.com/blah/ha'

                    @utils.follow_protocol?( url ).should be_true
                    @utils.skip_path?( url ).should be_false
                end
            end
            context 'other' do
                it 'returns false' do
                    @opts.url = 'http://test2.com/blah/ha'
                    @opts.https_only = true

                    url = 'stuff://test2.com/blah/ha'

                    @utils.follow_protocol?( url ).should be_false
                    @utils.skip_path?( url ).should be_true
                end
            end
        end
        context 'when the reference URL uses' do
            context 'HTTPS' do
                context 'and the checked URL uses' do
                    context 'HTTPS' do
                        context 'and Options#https_only is' do
                            context true do
                                it 'returns true' do
                                    @opts.url = 'https://test2.com/blah/ha'
                                    @opts.https_only = true

                                    url = 'https://test2.com/blah/ha'

                                    @utils.follow_protocol?( url ).should be_true
                                    @utils.skip_path?( url ).should be_false
                                end
                            end

                            context false do
                                it 'returns true' do
                                    @opts.url = 'https://test2.com/blah/ha'
                                    @opts.https_only = false

                                    url = 'https://test2.com/blah/ha'

                                    @utils.follow_protocol?( url ).should be_true
                                    @utils.skip_path?( url ).should be_false
                                end
                            end
                        end
                    end
                    context 'HTTP' do
                        context 'and Options#https_only is' do
                            context true do
                                it 'returns false' do
                                    @opts.url = 'https://test2.com/blah/ha'
                                    @opts.https_only = true

                                    url = 'http://test2.com/blah/ha'

                                    @utils.follow_protocol?( url ).should be_false
                                    @utils.skip_path?( url ).should be_true
                                end
                            end

                            context false do
                                it 'returns true' do
                                    @opts.url = 'https://test2.com/blah/ha'
                                    @opts.https_only = false

                                    url = 'http://test2.com/blah/ha'

                                    @utils.follow_protocol?( url ).should be_true
                                    @utils.skip_path?( url ).should be_false
                                end
                            end
                        end
                    end
                end
            end

            context 'HTTP' do
                context 'and the checked URL uses' do
                    context 'HTTPS' do
                        context 'and Options#https_only is' do
                            context true do
                                it 'returns true' do
                                    @opts.url = 'http://test2.com/blah/ha'
                                    @opts.https_only = true

                                    url = 'https://test2.com/blah/ha'

                                    @utils.follow_protocol?( url ).should be_true
                                    @utils.skip_path?( url ).should be_false
                                end
                            end

                            context false do
                                it 'returns true' do
                                    @opts.url = 'http://test2.com/blah/ha'
                                    @opts.https_only = false

                                    url = 'https://test2.com/blah/ha'

                                    @utils.follow_protocol?( url ).should be_true
                                    @utils.skip_path?( url ).should be_false
                                end
                            end
                        end
                    end
                    context 'HTTP' do
                        context 'and Options#https_only is' do
                            context true do
                                it 'returns true' do
                                    @opts.url = 'http://test2.com/blah/ha'
                                    @opts.https_only = true

                                    url = 'http://test2.com/blah/ha'

                                    @utils.follow_protocol?( url ).should be_true
                                    @utils.skip_path?( url ).should be_false
                                end
                            end

                            context false do
                                it 'returns true' do
                                    @opts.url = 'http://test2.com/blah/ha'
                                    @opts.https_only = false

                                    url = 'http://test2.com/blah/ha'

                                    @utils.follow_protocol?( url ).should be_true
                                    @utils.skip_path?( url ).should be_false
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    describe '#get_path' do
        context 'when the url only has a path' do
            it 'does not change it' do
                uri_with_path = 'http://test.com/some/path/'
                @utils.get_path( uri_with_path ).should == uri_with_path
            end
        end

        context 'when the url only has a path without a terminating slash' do
            it 'appends a slash to it' do
                uri_with_path = 'http://test.com/some/path'
                @utils.get_path( uri_with_path ).should == uri_with_path + '/'
            end
        end

        context 'when the url has elements past its path' do
            context 'with a slash after its path' do
                it 'only returns it up to its path with a terminating slash' do
                    uri = 'http://test.com/some/path/'
                    uri2 = uri + '?query=val&var=val2#frag'
                    @utils.get_path( uri2 ).should == uri
                end
            end

            context 'with aout slash after its path' do
                it 'only returns it up to its path with a terminating slash' do
                    uri = 'http://test.com/some/path'
                    uri2 = uri + '?query=val&var=val2#frag'
                    @utils.get_path( uri2 ).should == uri + '/'
                end
            end
        end
    end

    describe '#seed' do
        it 'returns a random string' do
            @utils.seed.class.should == String
        end
    end

    describe '#normalize_url' do
        it 'should clean the URL' do
            [
                'another/path',
                '/some/path',
                'http://test.com',
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
                'http://test.com/login.php?goto?=domain.tld/index.php'
            ].each { |p| @utils.normalize_url( p ).should == Arachni::URI.normalize( p ) }
        end
    end

    describe '#exception_jail' do
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
