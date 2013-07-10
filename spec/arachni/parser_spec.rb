require 'spec_helper'

describe Arachni::Parser do
    before( :all ) do
        @utils = Arachni::Utilities
        @opts = Arachni::Options.instance
        @opts.url = @utils.normalize_url( web_server_url_for( :parser ) )
        @opts.audit_links = true
        @opts.audit_forms = true
        @opts.audit_cookies = true
        @opts.audit_headers = true

        @url = @utils.normalize_url( @opts.url + '/?query_var_input=query_var_val' )

        @opts.cookies = [
            Arachni::Element::Cookie.new( @url,
                { 'name_from_cookiejar' => 'val_from_cookiejar' }
            )
        ]

        @response = Arachni::HTTP.get(
            @url,
            async: false,
            remove_id: true
        ).response
        @parser = Arachni::Parser.new( @response, @opts )
    end

    describe '#url' do
        it 'holds the effective URL of the response' do
            @parser.url.should == @url
        end
    end

    describe '#opts' do
        it 'holds the provided opts' do
            @parser.opts.should == @opts
        end
    end

    describe '#run' do
        it 'returns a Page' do
            page = @parser.run

            page.class.should == Arachni::Page
            page.url.should == @parser.url
            page.code.should == @response.code
            page.method.should == @response.request.method.to_s
            page.query_vars.should == { 'query_var_input' => 'query_var_val' }
            page.body.should == @response.body
            page.response_headers.should == @response.headers_hash
            page.paths.should == @parser.paths

            link = Arachni::Element::Link.new( @url,
                inputs: @parser.link_vars( @url )
            )

            page.links.should == @parser.links | [link]
            page.forms.should == @parser.forms
            page.cookies.should == @parser.cookies | @opts.cookies | Arachni::HTTP.instance.cookie_jar.cookies
            page.headers.should == @parser.headers
            page.cookiejar.should == @parser.cookies | @opts.cookies
        end

        it 'forces page\'s cookies\'s action to the response\'s effective URL' do
            url = 'http://stuff.com/'
            response = Typhoeus::Response.new(
                effective_url: url,
                body: '',
                request: Typhoeus::Request.new( url ),
                headers: {
                    'Content-Type' => 'text/html',
                    'Set-Cookie'   => 'cname=cval'
                }
            )
            parser = Arachni::Parser.new( response, @opts )
            cookies = parser.page.cookies
            cookies.size.should == 2
            cookies.map{ |c| c.action }.uniq.should == [url]
        end

        context 'when Options.no_fingerprint is' do
            context false do
                it 'performs platform fingerprinting' do
                    Arachni::Options.no_fingerprinting = false

                    response = Typhoeus::Response.new(
                        effective_url: 'http://stuff.com/index.php'
                    )
                    parser = Arachni::Parser.new( response, @opts )
                    parser.page.platforms.should be_any
                end
            end

            context true do
                it 'does not perform platform fingerprinting' do
                    Arachni::Options.no_fingerprinting = true

                    response = Typhoeus::Response.new(
                        effective_url: 'http://stuff.com/index2.php'
                    )
                    parser = Arachni::Parser.new( response, @opts )
                    parser.page.platforms.should be_empty
                end
            end
        end
    end

    describe '#text?' do
        context 'when the response is text based' do
            it { @parser.text?.should be_true }
        end

        context 'when the response is not text based' do
            before {
                res = Typhoeus::Response.new( effective_url: @url )
                @parser_2 = Arachni::Parser.new( res, @opts )
            }
            it { @parser_2.text?.should be_false }
        end
    end

    describe '#doc' do
        context 'when the response is text based' do
            it 'returns the parsed document' do
                @parser.doc.class == Nokogiri::HTML::Document
            end
        end

        context 'when the response is not text based' do
            it 'returns nil' do
                res = Typhoeus::Response.new( effective_url: @url )
                Arachni::Parser.new( res, @opts ).doc.should be_nil
            end
        end

    end

    describe '#links' do
        context 'when the response was a result of redirection' do
            it 'includes the URL in the array' do
                url = 'http://stuff.com/'
                response = Typhoeus::Response.new(
                    effective_url: url,
                    body: '',
                    headers_hash: {
                        'Content-Type' => 'text/html',
                        'Location'     => url
                    }
                )
                parser = Arachni::Parser.new( response, @opts )
                parser.links.size == 1
            end
        end
        context 'when the response URL contains auditable inputs' do
            it 'includes the URL in the array' do
                url = 'http://stuff.com/?stuff=ba'
                response = Typhoeus::Response.new(
                    effective_url: url,
                    body: '',
                    headers_hash: {
                        'Content-Type' => 'text/html'
                    }
                )
                parser = Arachni::Parser.new( response, @opts )
                parser.links.size == 1
                parser.links.first.auditable.should == { 'stuff' => 'ba' }
            end
        end
        context 'otherwise' do
            it 'should not include it the response URL' do
                url = 'http://stuff.com/'
                response = Typhoeus::Response.new(
                    effective_url: url,
                    body: '',
                    headers_hash: {
                        'Content-Type' => 'text/html'
                    }
                )
                parser = Arachni::Parser.new( response, @opts )
                parser.links.should be_empty
            end
        end
        context 'when the response is not text based' do
            it 'returns nil' do
                res = Typhoeus::Response.new( effective_url: @url )
                Arachni::Parser.new( res, @opts ).links.should be_empty
            end
        end
    end

    describe '#forms' do
        it 'returns an array of parsed forms' do
            @parser.forms.size.should == 2

            form = @parser.forms.first
            form.action.should == @utils.normalize_url( @opts.url + '/form' )
            form.url.should == @url

            form.auditable.should == {
                "form_input_1" => "form_val_1",
                "form_input_2" => "form_val_2"
            }
            form.method.should == 'post'
            form.raw.should == {
                    "attrs" => {
                    "method" => "post",
                    "action" => form.action,
                      "name" => "my_form"
                },
                 "textarea" => [],
                   "select" => [],
                    "input" => [
                    {
                         "type" => "text",
                         "name" => "form_input_1",
                        "value" => "form_val_1"
                    },
                    {
                         "type" => "text",
                         "name" => "form_input_2",
                        "value" => "form_val_2"
                    },
                    {
                        "type" => "submit"
                    }
                ],
                "auditable" => [
                    {
                         "type" => "text",
                         "name" => "form_input_1",
                        "value" => "form_val_1"
                    },
                    {
                         "type" => "text",
                         "name" => "form_input_2",
                        "value" => "form_val_2"
                    },
                    {
                        "type" => "submit"
                    }
                ]
            }

            form = @parser.forms.last
            form.action.should == @utils.normalize_url( @opts.url + '/form_2')
            form.url.should == @url
            form.auditable.should == { "form_2_input_1" => "form_2_val_1" }
        end

        context 'when passed secondary responses' do
            it 'identifies the nonces' do
                responses = []

                responses << Arachni::HTTP.get( @opts.url + 'with_nonce', async: false ).response
                responses << Arachni::HTTP.get( @opts.url + 'with_nonce', async: false ).response

                parser = Arachni::Parser.new( responses, @opts )
                parser.forms.map { |f| f.nonce_name }.sort.should == %w(nonce nonce2).sort
            end
        end
        context 'when the response is not text based' do
            it 'returns nil' do
                res = Typhoeus::Response.new( effective_url: @url )
                Arachni::Parser.new( res, @opts ).forms.should be_empty
            end
        end
    end

    describe '#cookies' do
        it 'returns an array of cookies' do
            @parser.cookies.size.should == 3

            cookies = @parser.cookies

            cookie = cookies.pop
            cookie.action.should == @url
            cookie.auditable.should == { 'cookie_input2' => 'cookie_val2' }
            cookie.method.should == 'get'
            cookie.secure?.should be_false
            cookie.http_only?.should be_false
            cookie.url.should == @url

            cookie = cookies.pop
            cookie.action.should == @url
            cookie.auditable.should == { 'cookie_input' => 'cookie_val' }
            cookie.method.should == 'get'
            cookie.secure?.should be_true
            cookie.http_only?.should be_true
            cookie.url.should == @url

            cookie = cookies.pop
            cookie.action.should == @url
            cookie.auditable.should == { "http_equiv_cookie_name" => "http_equiv_cookie_val" }
            cookie.secure?.should be_true
            cookie.http_only?.should be_true
            cookie.method.should == 'get'
            cookie.url.should == @url
        end
    end

    context 'without base' do
        describe '#base' do
            it 'returns nil' do
                @parser.base.should == nil
            end
        end

        describe '#to_absolute' do
            it 'converts a relative path to absolute' do
                @parser.to_absolute( 'relative/path' ).should == @utils.normalize_url( "#{@opts.url}/relative/path" )
            end
        end

        describe '#links' do
            it 'returns an array of links' do
                links = @parser.links
                links.size.should == 2

                link = links.first
                link.action.should == @utils.normalize_url( @url )
                link.auditable.should == { 'query_var_input' => 'query_var_val' }
                link.method.should == 'get'
                link.url.should == @url

                link = links.last
                link.action.should == @utils.normalize_url( @opts.url + '/link?link_input=link_val' )
                link.auditable.should == { 'link_input' => 'link_val' }
                link.method.should == 'get'
                link.url.should == @url
            end
        end

        describe '#paths' do
            it 'returns an array of all paths found in the page as absolute URLs' do
                paths = [
                    "link?link_input=link_val",
                    "form",
                    "form_2",
                ].map { |p| @utils.normalize_url( @opts.url.to_s + '/' + p ) }

                (@parser.paths & paths).sort.should == paths.sort
            end
        end
    end

    context 'with base' do
        before {
            @url_with_base = @utils.normalize_url( @opts.url + '/with_base?stuff=ha' )
            res = Arachni::HTTP.instance.get(
                @url_with_base,
                async: false,
                remove_id: true
            ).response
            @parser_with_base = Arachni::Parser.new( res, @opts )
        }

        describe '#base' do
            it 'returns the base href attr' do
                @parser_with_base.base.should == @utils.normalize_url( "#{@opts.url.to_s}/this_is_the_base/" )
            end
        end

        describe '#to_absolute' do
            it 'converts a relative path to absolute' do
                @parser_with_base.to_absolute( 'relative/path' ).should == @utils.normalize_url( "#{@parser_with_base.base}relative/path" )
            end
        end

        describe '#links' do
            it 'returns an array of links' do
                links = @parser_with_base.links
                links.size.should == 2

                link = links.first
                link.action.should == @url_with_base
                link.auditable.should ==  { 'stuff' => 'ha' }
                link.method.should == 'get'
                link.url.should == @url_with_base

                link = links.last
                link.action.should == @parser_with_base.base + 'link_with_base?link_input=link_val'
                link.auditable.should == { 'link_input' => 'link_val' }
                link.method.should == 'get'
                link.url.should == @url_with_base
            end
        end

        describe '#paths' do
            it 'returns an array of all paths found in the page as absolute URLs' do
                paths = [
                    "",
                    "link_with_base?link_input=link_val",
                ].map { |p| @parser_with_base.base + '' + p }

                (@parser_with_base.paths & paths).sort.should == paths.sort
            end
        end
    end

    describe '#headers' do
        it 'returns an array of headers' do
            @parser.headers.each { |h| h.class.should == Arachni::Element::Header }
        end
    end

    describe '#link_vars' do
        it 'returns a hash of link query inputs' do
            @parser.link_vars( @url ).should == { "query_var_input" => "query_var_val" }
        end
    end

end
