# encoding: utf-8
require 'spec_helper'

describe Arachni::Utilities do

    before( :each ) do
        @opts = Arachni::Options.reset
    end

    subject { Arachni::Utilities }

    describe '#caller_name' do
        it 'returns the filename of the caller' do
            subject.caller_name.should == 'example'
        end
    end

    describe '#caller_path' do
        it 'returns the filepath of the caller' do
            subject.caller_path.should == Kernel.caller.first.match( /^(.+):\d/ )[1]
        end
    end

    {
        forms_from_response:     [Arachni::Element::Form, :from_response],
        forms_from_document:     [Arachni::Element::Form, :from_document],
        form_encode:             [Arachni::Element::Form, :encode],
        form_decode:             [Arachni::Element::Form, :decode],
        form_parse_request_body: [Arachni::Element::Form, :parse_request_body],
        links_from_response:     [Arachni::Element::Link, :from_response],
        links_from_document:     [Arachni::Element::Link, :from_document],
        link_parse_query:        [Arachni::Element::Link, :parse_query],
        cookies_from_response:   [Arachni::Element::Cookie, :from_response],
        cookies_from_document:   [Arachni::Element::Cookie, :from_document],
        cookies_from_file:       [Arachni::Element::Cookie, :from_file],
        cookie_encode:           [Arachni::Element::Cookie, :encode],
        cookie_decode:           [Arachni::Element::Cookie, :decode],
        parse_set_cookie:        [Arachni::Element::Cookie, :parse_set_cookie],
        page_from_response:      [Arachni::Page, :from_response],
        page_from_url:           [Arachni::Page, :from_url],
        html_decode:             [CGI, :unescapeHTML],
        html_unescape:           [CGI, :unescapeHTML],
        html_encode:             [CGI, :escapeHTML],
        html_escape:             [CGI, :escapeHTML],
        uri_parse:               [Arachni::URI, :parse],
        uri_encode:              [Arachni::URI, :encode],
        uri_decode:              [Arachni::URI, :decode],
        normalize_url:           [Arachni::URI, :normalize]
    }.each do |m, (klass, delegated)|
        describe "##{m}" do
            it "delegates to #{klass}.#{delegated}" do
                ret = :blah
                arg = 'stuff'

                klass.should receive(delegated).with(arg)
                klass.stub(delegated){ ret }

                subject.send( m, arg ).should == ret
            end
        end
    end

    describe '#uri_parser' do
        it 'returns a URI::Parser' do
            subject.uri_parser.class.should == ::URI::Parser
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

            parsed_uri = subject.uri_parse( uri )

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
            subject.uri_decode( uri ).should == "my test.asp?name=ståle&car=saab"
        end
    end

    describe '#to_absolute' do
        it 'converts a relative path to absolute' do
            @opts.url  = 'http://test2.com/blah/ha'
            rel  = '/test'
            rel2 = 'test2'
            subject.to_absolute( rel ).should == "http://test2.com" + rel
            subject.to_absolute( rel2 ).should == "http://test2.com/blah/" + rel2
        end

        context 'when called with a 2nd parameter' do
            it 'uses it as a reference for the conversion' do
                abs  = 'http://test.com/blah/ha'
                rel  = '/test'
                rel2 = 'test2'
                subject.to_absolute( rel, abs ).should == "http://test.com" + rel
                subject.to_absolute( rel2, abs ).should == "http://test.com/blah/" + rel2
                subject.to_absolute( rel2, abs + '/' ).should == "http://test.com/blah/ha/" + rel2
            end
        end
    end

    describe '#redundant_path?' do
        context "when a URL's counter reaches 0" do
            it 'returns true' do
                Arachni::Options.scope.redundant_path_patterns = { /match_this/ => 10 }

                url = 'http://stuff.com/match_this'
                10.times do
                    subject.redundant_path?( url ).should be_false
                end

                subject.redundant_path?( url ).should be_true
            end
        end
        context "when a URL's counter has not reached 0" do
            it 'returns false' do
                Arachni::Options.scope.redundant_path_patterns = { /match_this/ => 11 }

                url = 'http://stuff.com/match_this'
                10.times do
                    subject.redundant_path?( url ).should be_false
                end

                subject.redundant_path?( url ).should be_false
            end
        end
    end

    describe '#path_in_domain?' do
        before { @opts.url = 'http://bar.com' }

        context 'when a second argument (reference URL) is provided' do
            context 'with a path that is in the domain' do
                it 'returns true' do
                    subject.path_in_domain?( 'http://yes.com/foo', 'http://yes.com' ).should be_true
                end
            end
            context 'with a path that is outside the domain' do
                it 'returns true' do
                    subject.path_in_domain?( 'http://no.com/foo', 'http://yes.com' ).should be_false
                end
            end
        end

        context 'when follow subdomains is disabled' do
            before { @opts.scope.include_subdomains = false }

            context 'with a URL with a different domain' do
                it 'returns false' do
                    subject.path_in_domain?( 'http://google.com' ).should be_false
                    subject.skip_path?( 'http://google.com' ).should be_true
                end
            end

            context 'with a URL with the same domain' do
                it 'returns true' do
                    subject.path_in_domain?( 'http://bar.com/test/' ).should be_true
                    subject.skip_path?( 'http://bar.com/test/' ).should be_false
                end
            end


            context 'with a URL with a different subdomain' do
                it 'returns false' do
                    subject.path_in_domain?( 'http://test.bar.com/test' ).should be_false
                    subject.skip_path?( 'http://test.bar.com/test' ).should be_true
                end
            end
        end

        context 'when follow subdomains is disabled' do
            before { @opts.scope.include_subdomains = true }

            context 'with a URL with a different domain' do
                it 'returns false' do
                    subject.path_in_domain?( 'http://google.com' ).should be_false
                    subject.skip_path?( 'http://google.com' ).should be_true
                end
            end

            context 'with a URL with the same domain' do
                it 'returns true' do
                    subject.path_in_domain?( 'http://bar.com/test/' ).should be_true
                    subject.skip_path?( 'http://bar.com/test/' ).should be_false
                end
            end


            context 'with a URL with a different subdomain' do
                it 'returns true' do
                    subject.path_in_domain?( 'http://test.bar.com/test' ).should be_true
                    subject.skip_path?( 'http://test.bar.com/test' ).should be_false
                end
            end
        end
    end

    describe '#exclude_path?' do
        before { @opts.scope.exclude_path_patterns << /skip_me/ }

        context 'when a path matches an exclude rule' do
            it 'returns true' do
                subject.exclude_path?( 'skip_me' ).should be_true
                subject.skip_path?( 'http://bar.com/skip_me' ).should be_true
            end
        end

        context 'when a path does not match an exclude rule' do
            it 'returns false' do
                subject.exclude_path?( 'not_me' ).should be_false
                subject.skip_path?( 'http://bar.com/not_me' ).should be_false
            end
        end
    end

    describe '#skip_path?' do
        context 'when an error occurs' do
            it 'returns true' do
                subject.skip_path?( 'http://test.com/' ).should be_false
                subject.stub(:follow_protocol?) { raise }
                subject.skip_path?( 'http://test.com/' ).should be_true
            end
        end
    end

    describe '#skip_page?' do
        before { @opts.scope.exclude_page_patterns << /ignore me/ }

        context 'when the page DOM depth limit has been exceeded' do
            it 'returns false' do
                page = Arachni::Page.from_data(
                    url:         'http://test',
                    dom:         {
                        transitions: [
                             { page: :load },
                             { "<a href='javascript:click();'>" => :click },
                             { "<button dblclick='javascript:doubleClick();'>" => :ondblclick }
                         ].map { |t| Arachni::Page::DOM::Transition.new *t.first }
                    }
                )
                subject.skip_page?( page ).should be_false

                @opts.scope.dom_depth_limit = 2
                subject.skip_page?( page ).should be_true
            end
        end

        context 'when the body matches an ignore rule' do
            it 'returns true' do
                page = Arachni::Page.from_data( url: 'http://test/', body: 'ignore me' )
                subject.skip_page?( page ).should be_true
            end
        end

        context 'when the body does not match an ignore rule' do
            it 'returns false' do
                page = Arachni::Page.from_data(
                    url: 'http://test/',
                    body: 'not me'
                )
                subject.skip_page?( page ).should be_false
            end
        end
    end

    describe '#skip_response?' do
        before { @opts.scope.exclude_page_patterns << /ignore me/ }

        context 'when the body matches an ignore rule' do
            it 'returns true' do
                res = Arachni::HTTP::Response.new( url: 'http://stuff/', body: 'ignore me' )
                subject.skip_response?( res ).should be_true
            end
        end

        context 'when the body does not match an ignore rule' do
            it 'returns false' do
                res = Arachni::HTTP::Response.new(
                    url: 'http://test/',
                    body: 'not me'
                )
                subject.skip_response?( res ).should be_false
            end
        end
    end

    describe '#include_path?' do
        before { @opts.scope.include_path_patterns << /include_me/ }

        context 'when a path matches an include rule' do
            it 'returns true' do
                subject.include_path?( 'include_me' ).should be_true
                subject.skip_path?( 'http://bar.com/include_me' ).should be_false
            end
        end

        context 'when a path does not match an include rule' do
            it 'returns false' do
                subject.include_path?( 'not_me' ).should be_false
                subject.skip_path?( 'http://bar.com/not_me' ).should be_true
            end
        end
    end

    describe '#skip_resource?' do
        before do
            @opts.scope.exclude_page_patterns << /ignore\s+me/m
            @opts.scope.exclude_path_patterns << /ignore/
        end

        context 'when passed a' do
            context Arachni::HTTP::Response do

                context 'whose body matches an ignore rule' do
                    it 'returns true' do
                        res = Arachni::HTTP::Response.new(
                            url: 'http://stuff/here',
                            body: 'ignore me'
                        )
                        subject.skip_resource?( res ).should be_true
                    end
                end

                context 'whose the body does not match an ignore rule' do
                    it 'returns false' do
                        res = Arachni::HTTP::Response.new(
                            url: 'http://stuff/here',
                            body: 'stuff'
                        )
                        subject.skip_resource?( res ).should be_false
                    end
                end

                context 'whose URL matches an exclude rule' do
                    it 'returns true' do
                        res = Arachni::HTTP::Response.new(
                            url: 'http://stuff/here/to/ignore/',
                            body: 'ignore me'
                        )
                        subject.skip_resource?( res ).should be_true
                    end
                end

                context 'whose URL does not match an exclude rule' do
                    it 'returns false' do
                        res = Arachni::HTTP::Response.new(
                            url: 'http://stuff/here',
                            body: 'stuff'
                        )
                        subject.skip_resource?( res ).should be_false
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
                        subject.skip_resource?( page ).should be_true
                    end
                end

                context 'whose the body does not match an ignore rule' do
                    it 'returns false' do
                        page = Arachni::Page.from_data(
                            url:   'http://stuff/here',
                            body: 'stuff'
                        )
                        subject.skip_resource?( page ).should be_false
                    end
                end

                context 'whose URL matches an exclude rule' do
                    it 'returns true' do
                        res = Arachni::Page.from_data(
                            url:   'http://stuff/here/to/ignore/',
                            body: 'ignore me'
                        )
                        subject.skip_resource?( res ).should be_true
                    end
                end

                context 'whose URL does not match an exclude rule' do
                    it 'returns false' do
                        res = Arachni::Page.from_data(
                            url:  'http://stuff/here',
                            body: 'stuff'
                        )
                        subject.skip_resource?( res ).should be_false
                    end
                end

            end

            context String do
                context 'with multiple lines' do
                    context 'which matches an ignore rule' do
                        it 'returns true' do
                            s = "ignore \n me"
                            subject.skip_resource?( s ).should be_true
                        end
                    end

                    context 'which does not match an ignore rule' do
                        it 'returns false' do
                            s = "multi \n line \n stuff here"
                            subject.skip_resource?( s ).should be_false
                        end
                    end
                end

                context 'with a single line' do
                    context 'which matches an exclude rule' do
                        it 'returns true' do
                            s = 'ignore/this/path'
                            subject.skip_resource?( s ).should be_true
                        end
                    end

                    context 'which does not match an exclude rule' do
                        it 'returns false' do
                            s = 'stuf/here/'
                            subject.skip_resource?( s ).should be_false
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
                    @opts.scope.https_only = true

                    url = 'https://test2.com/blah/ha'

                    subject.follow_protocol?( url ).should be_true
                    subject.skip_path?( url ).should be_false
                end
            end
            context 'HTTPS' do
                it 'returns true' do
                    @opts.url = 'https://test2.com/blah/ha'
                    @opts.scope.https_only = true

                    url = 'https://test2.com/blah/ha'

                    subject.follow_protocol?( url ).should be_true
                    subject.skip_path?( url ).should be_false
                end
            end
            context 'other' do
                it 'returns false' do
                    @opts.url = 'http://test2.com/blah/ha'
                    @opts.scope.https_only = true

                    url = 'stuff://test2.com/blah/ha'

                    subject.follow_protocol?( url ).should be_false
                    subject.skip_path?( url ).should be_true
                end
            end
        end
        context 'when the reference URL uses' do
            context 'HTTPS' do
                context 'and the checked URL uses' do
                    context 'HTTPS' do
                        context 'and Options#scope_https_only is' do
                            context true do
                                it 'returns true' do
                                    @opts.url = 'https://test2.com/blah/ha'
                                    @opts.scope.https_only = true

                                    url = 'https://test2.com/blah/ha'

                                    subject.follow_protocol?( url ).should be_true
                                    subject.skip_path?( url ).should be_false
                                end
                            end

                            context false do
                                it 'returns true' do
                                    @opts.url = 'https://test2.com/blah/ha'
                                    @opts.scope.https_only = false

                                    url = 'https://test2.com/blah/ha'

                                    subject.follow_protocol?( url ).should be_true
                                    subject.skip_path?( url ).should be_false
                                end
                            end
                        end
                    end
                    context 'HTTP' do
                        context 'and Options#scope_https_only is' do
                            context true do
                                it 'returns false' do
                                    @opts.url = 'https://test2.com/blah/ha'
                                    @opts.scope.https_only = true

                                    url = 'http://test2.com/blah/ha'

                                    subject.follow_protocol?( url ).should be_false
                                    subject.skip_path?( url ).should be_true
                                end
                            end

                            context false do
                                it 'returns true' do
                                    @opts.url = 'https://test2.com/blah/ha'
                                    @opts.scope.https_only = false

                                    url = 'http://test2.com/blah/ha'

                                    subject.follow_protocol?( url ).should be_true
                                    subject.skip_path?( url ).should be_false
                                end
                            end
                        end
                    end
                end
            end

            context 'HTTP' do
                context 'and the checked URL uses' do
                    context 'HTTPS' do
                        context 'and Options#scope_https_only is' do
                            context true do
                                it 'returns true' do
                                    @opts.url = 'http://test2.com/blah/ha'
                                    @opts.scope.https_only = true

                                    url = 'https://test2.com/blah/ha'

                                    subject.follow_protocol?( url ).should be_true
                                    subject.skip_path?( url ).should be_false
                                end
                            end

                            context false do
                                it 'returns true' do
                                    @opts.url = 'http://test2.com/blah/ha'
                                    @opts.scope.https_only = false

                                    url = 'https://test2.com/blah/ha'

                                    subject.follow_protocol?( url ).should be_true
                                    subject.skip_path?( url ).should be_false
                                end
                            end
                        end
                    end
                    context 'HTTP' do
                        context 'and Options#scope_https_only is' do
                            context true do
                                it 'returns true' do
                                    @opts.url = 'http://test2.com/blah/ha'
                                    @opts.scope.https_only = true

                                    url = 'http://test2.com/blah/ha'

                                    subject.follow_protocol?( url ).should be_true
                                    subject.skip_path?( url ).should be_false
                                end
                            end

                            context false do
                                it 'returns true' do
                                    @opts.url = 'http://test2.com/blah/ha'
                                    @opts.scope.https_only = false

                                    url = 'http://test2.com/blah/ha'

                                    subject.follow_protocol?( url ).should be_true
                                    subject.skip_path?( url ).should be_false
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
                subject.get_path( uri_with_path ).should == uri_with_path
            end
        end

        context 'when the url only has a path without a terminating slash' do
            it 'appends a slash to it' do
                uri_with_path = 'http://test.com/some/path'
                subject.get_path( uri_with_path ).should == uri_with_path + '/'
            end
        end

        context 'when the url has elements past its path' do
            context 'with a slash after its path' do
                it 'only returns it up to its path with a terminating slash' do
                    uri = 'http://test.com/some/path/'
                    uri2 = uri + '?query=val&var=val2#frag'
                    subject.get_path( uri2 ).should == uri
                end
            end

            context 'with aout slash after its path' do
                it 'only returns it up to its path with a terminating slash' do
                    uri = 'http://test.com/some/path'
                    uri2 = uri + '?query=val&var=val2#frag'
                    subject.get_path( uri2 ).should == uri + '/'
                end
            end
        end
    end

    describe '#seed' do
        it 'returns a random string' do
            subject.seed.class.should == String
        end
    end

    describe '#secs_to_hms' do
        it 'converts seconds to HOURS:MINUTES:SECONDS' do
            subject.secs_to_hms( 0 ).should == '00:00:00'
            subject.secs_to_hms( 1 ).should == '00:00:01'
            subject.secs_to_hms( 60 ).should == '00:01:00'
            subject.secs_to_hms( 60*60 ).should == '01:00:00'
            subject.secs_to_hms( 60*60 + 60 + 1 ).should == '01:01:01'
        end
    end

    describe '#exception_jail' do
        context 'when no error occurs' do
            it 'returns the return value of the block' do
                subject.exception_jail { :stuff }.should == :stuff
            end
        end

        context "when a #{RuntimeError} occurs" do
            context 'and raise_exception is' do
                context 'default' do
                    it 're-raises the exception' do
                        expect do
                            subject.exception_jail { raise }
                        end.to raise_error RuntimeError
                    end
                end

                context true do
                    it 're-raises the exception' do
                        expect do
                            subject.exception_jail( true ) { raise }
                        end.to raise_error RuntimeError
                    end
                end

                context false do
                    it 'returns nil' do
                        subject.exception_jail( false ) { raise }.should be_nil
                    end
                end
            end
        end

        context "when an #{Exception} occurs" do
            context 'and raise_exception is' do
                context 'default' do
                    it 'does not rescue it' do
                        expect do
                            subject.exception_jail { raise Exception }
                        end.to raise_error Exception
                    end
                end

                context true do
                    it 'does not rescue it' do
                        expect do
                            subject.exception_jail( true ) { raise Exception }
                        end.to raise_error Exception
                    end
                end

                context false do
                    it 'does not rescue it' do
                        expect do
                            subject.exception_jail( false ) { raise Exception }
                        end.to raise_error Exception
                    end
                end
            end
        end
    end

end
