require 'spec_helper'

describe Arachni::Parser do
    before( :all ) do
        @utils = Arachni::Utilities
        @opts  = Arachni::Options.instance

        @opts.url = web_server_url_for( :parser )

        @url = @utils.normalize_url( @opts.url + '/?query_var_input=query_var_val' )

        @response = Arachni::HTTP::Client.get( @url, mode: :sync )
    end

    before :each do
        @opts.http.cookies = {
            'name_from_cookiejar' => 'val_from_cookiejar'
        }

        Arachni::HTTP::Client.reset
    end

    subject(:response) { @response }
    subject { Arachni::Parser.new( response ) }

    describe '#url' do
        it 'holds the effective URL of the response' do
            subject.url.should == @url
        end
    end

    describe '#link' do
        it 'returns the URL of the response as a Link' do
            subject.link.action.should == @opts.url
            subject.link.inputs.should == { 'query_var_input' => 'query_var_val' }
        end
    end

    describe '#body=' do
        let(:response) do
            url = 'http://stuff.com/'
            Arachni::HTTP::Response.new(
                url: url,
                body: '<a href="/?name=val">Stuff</a>',
                request: Arachni::HTTP::Request.new( url: url )
            )
        end

        it 'overrides the body of the HTTP response for the parsing process' do
            subject.body = '<a href="/?name2=val2">Stuff</a>'
            subject.links.size.should == 1
            subject.links.first.inputs.should == { 'name2' => 'val2' }
        end

        it 'clears the existing element cache' do
            subject.links.size.should == 1
            subject.links.first.inputs.should == { 'name' => 'val' }

            subject.body = '<a href="/?name2=val2">Stuff</a>'
            subject.links.size.should == 1
            subject.links.first.inputs.should == { 'name2' => 'val2' }
        end
    end

    describe '#page' do
        it 'returns a Page' do
            page = subject.page

            page.should be_kind_of Arachni::Page
            page.url.should == subject.url
            page.method.should == @response.request.method
            page.query_vars.should == { 'query_var_input' => 'query_var_val' }
            page.body.should == @response.body
            page.response.should == @response
            page.paths.should == subject.paths

            link = Arachni::Element::Link.new( url: @url, inputs: subject.link_vars )

            page.links.should == subject.links | [link]
            page.forms.should == subject.forms
            page.cookies.should == subject.cookies_to_be_audited
            page.headers.should == subject.headers

            page.cookiejar.should == subject.cookie_jar
        end
    end

    describe '#cookie_jar' do
        let(:response) do
            Arachni::HTTP::Response.new(
                url: @url,
                body: '',
                request: Arachni::HTTP::Request.new( url: @url ),
                headers: {
                    'Content-Type' => 'text/html',
                    'Set-Cookie'   => ['cname=cval', 'name_from_cookiejar=updated']
                }
            )
        end

        it 'returns cookies that need to be transmitted to the page' do
            subject.cookie_jar.map(&:inputs).should == [
                 { 'cname'               => 'cval' },
                 { 'name_from_cookiejar' => 'updated' }
            ]
        end
    end

    describe '#cookies_to_be_audited' do
        let(:response) do
            Arachni::HTTP::Response.new(
                url: @url,
                body: '',
                request: Arachni::HTTP::Request.new( url: @url ),
                headers: {
                    'Content-Type' => 'text/html',
                    'Set-Cookie'   => ['cname=cval', 'name_from_cookiejar=updated']
                }
            )
        end

        it 'returns all system cookies' do
            Arachni::HTTP::Client.cookie_jar.update( Arachni::Element::Cookie.new(
                url:    'http://stuff/',
                inputs: {
                    irrelevant: 'iv',
                    cname:      'oldvar'
                }
            ))

            subject.cookies_to_be_audited.map(&:inputs).should == [
                { 'cname'               => 'cval' },
                { 'name_from_cookiejar' => 'updated' },
                { 'irrelevant'          => 'iv' }
            ]
        end

        it 'forces the #action to the page URL' do
            cookies = subject.cookies_to_be_audited
            cookies.size.should == 2
            cookies.map { |c| c.action }.uniq.should == [@url]
        end
    end

    describe '#text?' do
        context 'when the response is text based' do
            it { subject.text?.should be_true }
        end

        context 'when the response is not text based' do
            let(:response) do
                 Arachni::HTTP::Response.new( url: @url, headers: {
                    'Content-Type' => 'bin/stuff'
                })
            end
            it { subject.text?.should be_false }
        end
    end

    describe '#doc' do
        context 'when the response is text based' do
            it 'returns the parsed document' do
                subject.document.class == Nokogiri::HTML::Document
            end
        end

        context 'when the response is not text based' do
            let(:response) do
                Arachni::HTTP::Response.new( url: @url, headers: {
                    'Content-Type' => 'bin/stuff'
                })
            end

            it 'returns nil' do
                subject.document.should be_nil
            end
        end

    end

    describe '#links' do
        context 'when the response was a result of redirection' do
            let(:response) do
                url = 'http://stuff.com/'
                response = Arachni::HTTP::Response.new(
                    url: url,
                    body: '',
                    headers: {
                        'Content-Type' => 'text/html',
                        'Location'     => url
                    }
                )
            end

            it 'includes the URL in the array' do
                subject.links.size == 1
            end
        end

        context 'when the response URL contains auditable inputs' do
            let(:response) do
                url = 'http://stuff.com/?stuff=ba'
                response = Arachni::HTTP::Response.new(
                    url: url,
                    body: '',
                    headers: {
                        'Content-Type' => 'text/html'
                    }
                )
            end

            it 'includes the URL in the array' do
                subject.links.size == 1
                subject.links.first.inputs.should == { 'stuff' => 'ba' }
            end
        end

        context 'otherwise' do
            let(:response) do
                url = 'http://stuff.com/'
                response = Arachni::HTTP::Response.new(
                    url: url,
                    body: '',
                    headers: {
                        'Content-Type' => 'text/html'
                    }
                )
            end

            it 'should not include it the response URL' do
                subject.links.should be_empty
            end
        end
        context 'when the response is not text based' do
            let(:response) do
                Arachni::HTTP::Response.new( url: 'http://stuff', headers: {
                    'Content-Type' => 'bin/stuff'
                })
            end

            it 'returns nil' do
                subject.links.should be_empty
            end

            context 'and the URL has query parameters' do
                let(:response) do
                    Arachni::HTTP::Response.new( url: @url, headers: {
                        'Content-Type' => 'bin/stuff'
                    })
                end

                it 'returns the URL parsed as a link' do
                    subject.links.size.should == 1
                    subject.links.first.should == subject.link
                end
            end
        end
    end

    describe '#forms' do
        it 'returns an array of parsed forms' do
            subject.forms.size.should == 2

            form = subject.forms.first
            form.action.should == @utils.normalize_url( @opts.url + '/form' )
            form.url.should == @url

            form.inputs.should == {
                "form_input_1" => "form_val_1",
                "form_input_2" => "form_val_2"
            }
            form.method.should == :post

            form = subject.forms.last
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
            let(:response) do
                Arachni::HTTP::Response.new( url: @url )
            end

            it 'returns nil' do
                subject.forms.should be_empty
            end
        end
    end

    describe '#cookies' do
        it 'returns an array of cookies' do
            subject.cookies.size.should == 3

            cookies = subject.cookies.sort_by { |cookie| cookie.name }.reverse

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

    describe '#link_template' do
        context 'when the response url matches a link template' do

            before(:each) do
                Arachni::Options.audit.link_templates = /param\/(?<param>\w+)/
            end

            let(:response) do
                url = @opts.url + 'test2/param/myvalue'
                Arachni::HTTP::Response.new( url: url )
            end

            it "returns a #{Arachni::Element::LinkTemplate}" do
                link = subject.link_template
                link.action.should == response.url
                link.url.should == response.url
                link.inputs.should == {
                    'param'  => 'myvalue'
                }
            end
        end
    end

    describe '#link_templates' do
        context 'when the response url matches a link template' do

            before(:each) do
                Arachni::Options.audit.link_templates = /param\/(?<param>\w+)/
            end

            let(:response) do
                url = @opts.url
                response = Arachni::HTTP::Response.new(
                    url: url,
                    body: '
                <html>
                    <body>
                        <a href="' + url + '/test2/param/myvalue"></a>
                    </body>
                </html>'
                )
            end

            it "returns a #{Arachni::Element::LinkTemplate}" do
                link = subject.link_templates.first
                link.action.should == response.url + 'test2/param/myvalue'
                link.url.should == response.url
                link.inputs.should == {
                    'param'  => 'myvalue'
                }
            end
        end
    end

    describe '#paths' do
        context 'when an error occurs' do
            it 'returns an empty array' do
                described_class.stub(:extractors){ raise }
                described_class.new( @response ).paths.should == []
            end
        end
    end

    context 'without base' do
        describe '#base' do
            it 'returns nil' do
                subject.base.should == nil
            end
        end

        describe '#to_absolute' do
            it 'converts a relative path to absolute' do
                subject.to_absolute( 'relative/path' ).should ==
                    @utils.normalize_url( "#{@opts.url}/relative/path" )
            end
        end

        describe '#links' do
            it 'returns an array of links' do
                links = subject.links
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

                (subject.paths & paths).sort.should == paths.sort
            end
        end
    end

    context 'with base' do
        let(:url) do
            @utils.normalize_url( @opts.url + '/with_base?stuff=ha' )
        end
        let(:response) do
            Arachni::HTTP::Client.get( url, mode: :sync )
        end

        describe '#base' do
            it 'returns the base href attr' do
                subject.base.should == @utils.normalize_url( "#{@opts.url.to_s}/this_is_the_base/" )
            end
        end

        describe '#to_absolute' do
            it 'converts a relative path to absolute' do
                subject.to_absolute( 'relative/path' ).should ==
                    @utils.normalize_url( "#{subject.base}relative/path" )
            end
        end

        describe '#links' do
            it 'returns an array of links' do
                links = subject.links
                links.size.should == 2

                link = links.first
                link.action.should == @opts.url + 'with_base'
                link.inputs.should ==  { 'stuff' => 'ha' }
                link.method.should == :get
                link.url.should == url

                link = links.last
                link.action.should == subject.base + 'link_with_base'
                link.inputs.should == { 'link_input' => 'link_val' }
                link.method.should == :get
                link.url.should == url
            end
        end

        describe '#paths' do
            it 'returns an array of all paths found in the page as absolute URLs' do
                paths = [
                    '',
                    'link_with_base?link_input=link_val'
                ].map { |p| subject.base + '' + p }

                (subject.paths & paths).sort.should == paths.sort
            end
        end
    end

    describe '#headers' do
        it 'returns an array of headers' do
            subject.headers.each { |h| h.class.should == Arachni::Element::Header }
        end
    end

    describe '#link_vars' do
        it 'returns a hash of link query inputs' do
            subject.link_vars.should == { 'query_var_input' => 'query_var_val' }
        end

        context "when there are #{Arachni::OptionGroups::Scope}#link_rewrites" do
            before :each do
                Arachni::Options.scope.link_rewrites = {
                    'stuff\/(\d+)' => '/stuff?id=\1'
                }
            end

            let(:response) do
                Arachni::HTTP::Client.get( "#{@opts.url}/stuff/13", mode: :sync )
            end

            it 'rewrites the url' do
                subject.link_vars.should == { 'id' => '13' }
            end
        end
    end

end
