require 'spec_helper'

describe Arachni::Parser do
    before( :all ) do
        @utils = Arachni::Utilities
        @opts = Arachni::Options.instance
        @opts.url = web_server_url_for( :parser )

        @url = @utils.normalize_url( @opts.url + '/?query_var_input=query_var_val' )

        @opts.http.cookies = {
            'name_from_cookiejar' => 'val_from_cookiejar'
        }

        @response = Arachni::HTTP::Client.get( @url, mode: :sync )
        @parser   = Arachni::Parser.new( @response, @opts )
    end

    describe '#url' do
        it 'holds the effective URL of the response' do
            @parser.url.should == @url
        end
    end

    describe '#link' do
        it 'returns the URL of the response as a Link' do
            @parser.link.action.should == @opts.url
            @parser.link.inputs.should == { 'query_var_input' => 'query_var_val' }
        end
    end

    describe '#body=' do
        it 'overrides the body of the HTTP response for the parsing process' do
            url = 'http://stuff.com/'
            response = Arachni::HTTP::Response.new(
                url: url,
                body: '<a href="/?name=val">Stuff</a>',
                request: Arachni::HTTP::Request.new( url: url )
            )

            parser = Arachni::Parser.new( response, @opts )
            parser.body = '<a href="/?name2=val2">Stuff</a>'
            parser.links.size.should == 1
            parser.links.first.inputs.should == { 'name2' => 'val2' }
        end

        it 'clears the existing element cache' do
            url = 'http://stuff.com/'
            response = Arachni::HTTP::Response.new(
                url: url,
                body: '<a href="/?name=val">Stuff</a>',
                request: Arachni::HTTP::Request.new( url: url )
            )

            parser = Arachni::Parser.new( response, @opts )
            parser.links.size.should == 1
            parser.links.first.inputs.should == { 'name' => 'val' }

            parser.body = '<a href="/?name2=val2">Stuff</a>'
            parser.links.size.should == 1
            parser.links.first.inputs.should == { 'name2' => 'val2' }
        end
    end

    describe '#page' do
        it 'returns a Page' do
            page = @parser.page

            page.should be_kind_of Arachni::Page
            page.url.should == @parser.url
            page.method.should == @response.request.method
            page.query_vars.should == { 'query_var_input' => 'query_var_val' }
            page.body.should == @response.body
            page.response.should == @response
            page.paths.should == @parser.paths

            link = Arachni::Element::Link.new( url: @url, inputs: @parser.link_vars )

            options_cookies = Arachni::Options.http.cookies.
                map { |cookie| Arachni::Element::Cookie.new( url: @url, inputs: Hash[[cookie]] ) }

            page.links.should == @parser.links | [link]
            page.forms.should == @parser.forms
            page.cookies.map(&:to_h).should == (@parser.cookies |
                options_cookies | Arachni::HTTP::Client.cookie_jar.cookies).
                map(&:to_h)
            page.headers.should == @parser.headers

            page.cookiejar.map(&:to_h).should eq @parser.cookies.map(&:to_h) | options_cookies.map(&:to_h)
        end

        it 'forces page\'s cookies\'s action to the response\'s effective URL' do
            url = 'http://stuff.com/'
            response = Arachni::HTTP::Response.new(
                url: url,
                body: '',
                request: Arachni::HTTP::Request.new( url: url ),
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
    end

    describe '#text?' do
        context 'when the response is text based' do
            it { @parser.text?.should be_true }
        end

        context 'when the response is not text based' do
            before {
                res = Arachni::HTTP::Response.new( url: @url, headers: {
                    'Content-Type' => 'bin/stuff'
                })
                @parser_2 = Arachni::Parser.new( res, @opts )
            }
            it { @parser_2.text?.should be_false }
        end
    end

    describe '#doc' do
        context 'when the response is text based' do
            it 'returns the parsed document' do
                @parser.document.class == Nokogiri::HTML::Document
            end
        end

        context 'when the response is not text based' do
            it 'returns nil' do
                res = Arachni::HTTP::Response.new( url: @url, headers: {
                    'Content-Type' => 'bin/stuff'
                })
                Arachni::Parser.new( res, @opts ).document.should be_nil
            end
        end

    end

    describe '#links' do
        context 'when the response was a result of redirection' do
            it 'includes the URL in the array' do
                url = 'http://stuff.com/'
                response = Arachni::HTTP::Response.new(
                    url: url,
                    body: '',
                    headers: {
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
                response = Arachni::HTTP::Response.new(
                    url: url,
                    body: '',
                    headers: {
                        'Content-Type' => 'text/html'
                    }
                )
                parser = Arachni::Parser.new( response, @opts )
                parser.links.size == 1
                parser.links.first.inputs.should == { 'stuff' => 'ba' }
            end
        end
        context 'otherwise' do
            it 'should not include it the response URL' do
                url = 'http://stuff.com/'
                response = Arachni::HTTP::Response.new(
                    url: url,
                    body: '',
                    headers: {
                        'Content-Type' => 'text/html'
                    }
                )
                parser = Arachni::Parser.new( response, @opts )
                parser.links.should be_empty
            end
        end
        context 'when the response is not text based' do
            context 'and the URL has query parameters' do
                it 'returns the URL parsed as a link' do
                    res = Arachni::HTTP::Response.new( url: @url, headers: {
                        'Content-Type' => 'bin/stuff'
                    })
                    links = Arachni::Parser.new( res, @opts ).links
                    links.size.should == 1
                    links.first.should == @parser.link
                end
            end

            it 'returns nil' do
                res = Arachni::HTTP::Response.new( url: 'http://stuff', headers: {
                    'Content-Type' => 'bin/stuff'
                })
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

            form.inputs.should == {
                "form_input_1" => "form_val_1",
                "form_input_2" => "form_val_2"
            }
            form.method.should == :post

            form = @parser.forms.last
            form.action.should == @utils.normalize_url( @opts.url + '/form_2' )
            form.url.should == @url
            form.inputs.should == { "form_2_input_1" => "form_2_val_1" }
        end

        context 'when passed secondary responses' do
            it 'identifies the nonces' do
                responses = []

                responses << Arachni::HTTP::Client.get( @opts.url + 'with_nonce', mode: :sync )
                responses << Arachni::HTTP::Client.get( @opts.url + 'with_nonce', mode: :sync )

                parser = Arachni::Parser.new( responses, @opts )
                parser.forms.map { |f| f.nonce_name }.sort.should == %w(nonce nonce2).sort
            end
        end
        context 'when the response is not text based' do
            it 'returns nil' do
                res = Arachni::HTTP::Response.new( url: @url )
                Arachni::Parser.new( res, @opts ).forms.should be_empty
            end
        end
    end

    describe '#cookies' do
        it 'returns an array of cookies' do
            @parser.cookies.size.should == 3

            cookies = @parser.cookies.sort_by { |cookie| cookie.name }.reverse

            cookie = cookies.pop
            cookie.action.should == @url
            cookie.inputs.should == { 'cookie_input' => 'cookie_val' }
            cookie.method.should == :get
            cookie.secure?.should be_true
            cookie.http_only?.should be_true
            cookie.url.should == @url

            cookie = cookies.pop
            cookie.action.should == @url
            cookie.inputs.should == { 'cookie_input2' => 'cookie_val2' }
            cookie.method.should == :get
            cookie.secure?.should be_false
            cookie.http_only?.should be_false
            cookie.url.should == @url

            cookie = cookies.pop
            cookie.action.should == @url
            cookie.inputs.should == { "http_equiv_cookie_name" => "http_equiv_cookie_val" }
            cookie.secure?.should be_true
            cookie.http_only?.should be_true
            cookie.method.should == :get
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
                link.action.should == @opts.url
                link.inputs.should == { 'query_var_input' => 'query_var_val' }
                link.method.should == :get
                link.url.should == @url

                link = links.last
                link.action.should == @utils.normalize_url( @opts.url + '/link' )
                link.inputs.should == { 'link_input' => 'link_val' }
                link.method.should == :get
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
            res = Arachni::HTTP::Client.get( @url_with_base, mode: :sync )
            @parser_with_base = Arachni::Parser.new( res, @opts )
        }

        describe '#base' do
            it 'returns the base href attr' do
                @parser_with_base.base.should == @utils.normalize_url( "#{@opts.url.to_s}/this_is_the_base/" )
            end
        end

        describe '#to_absolute' do
            it 'converts a relative path to absolute' do
                @parser_with_base.to_absolute( 'relative/path' ).should ==
                    @utils.normalize_url( "#{@parser_with_base.base}relative/path" )
            end
        end

        describe '#links' do
            it 'returns an array of links' do
                links = @parser_with_base.links
                links.size.should == 2

                link = links.first
                link.action.should == @opts.url + 'with_base'
                link.inputs.should ==  { 'stuff' => 'ha' }
                link.method.should == :get
                link.url.should == @url_with_base

                link = links.last
                link.action.should == @parser_with_base.base + 'link_with_base'
                link.inputs.should == { 'link_input' => 'link_val' }
                link.method.should == :get
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
            @parser.link_vars.should == { 'query_var_input' => 'query_var_val' }
        end

        context "when there are #{Arachni::OptionGroups::Scope}#link_rewrites" do
            it 'rewrites the url' do
                Arachni::Options.scope.link_rewrites = {
                    'stuff\/(\d+)' => '/stuff?id=\1'
                }

                url    = "#{@opts.url}/stuff/13"
                parser = described_class.new( Arachni::HTTP::Client.get( url, mode: :sync ) )

                parser.link_vars.should == { 'id' => '13' }
            end
        end
    end

end
