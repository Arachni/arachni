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

    let(:document) { described_class.parse response.body }
    let(:response) { @response }
    subject { Arachni::Parser.new( response ) }
    let(:from_response) { Arachni::Parser.new( response ) }
    let(:from_document) { Arachni::Parser.new( document ) }

    describe '#initialize' do
        context 'Arachni::Parser::Document' do
            subject { from_document }

            it 'sets it as #document' do
                expect(subject.document).to eq document
            end
        end

        context 'Arachni::HTTP::Response' do
            subject { from_response }

            it 'parses it' do
                expect(subject.body).to eq response.body
            end
        end

        context 'Array of Arachni::HTTP::Response' do
            subject do
                described_class.new(
                    [response,
                    Arachni::HTTP::Client.get( @url, mode: :sync )]
                )
            end

            it 'parses the first' do
                expect(subject.body).to eq response.body
            end
        end
    end

    describe '#response=' do
        subject { described_class.new( document ) }

        it 'sets the response' do
            expect(subject.response).to be_nil
            subject.response = response
            expect(subject.response).to eq response
        end
    end

    describe '#url' do
        it 'holds the effective URL of the response' do
            expect(subject.url).to eq(@url)
        end
    end

    describe '#link' do
        it 'returns the URL of the response as a Link' do
            expect(subject.link.action).to eq(@opts.url)
            expect(subject.link.inputs).to eq({ 'query_var_input' => 'query_var_val' })
        end
    end

    describe '#body' do
        context 'when the body has been explicitly set' do
            it 'returns it' do
                subject.body = 'blah'
                expect(subject.body). to eq 'blah'
            end
        end

        context 'when the parser was initialized from an HTTP::Response' do
            it 'returns the response body' do
                expect(from_response.body). to eq response.body
            end
        end

        context 'when the parser was initialized from a Document' do
            it 'returns nil' do
                expect(from_document.body). to be_nil
            end
        end
    end

    describe '#body=' do
        let(:response) do
            Arachni::HTTP::Response.new(
                url: @opts.url,
                body: '<a href="/?name=val">Stuff</a>',
                request: Arachni::HTTP::Request.new( url: @opts.url )
            )
        end

        it 'overrides the body of the HTTP response for the parsing process' do
            subject.body = '<html><div><a href="/?name2=val2">Stuff</a></div></html>'
            expect(subject.links.size).to eq(1)
            expect(subject.links.first.inputs).to eq({ 'name2' => 'val2' })
        end

        it 'clears the existing element cache' do
            expect(subject.links.size).to eq(1)
            expect(subject.links.first.inputs).to eq({ 'name' => 'val' })

            subject.body = '<a href="/?name2=val2">Stuff</a>'
            expect(subject.links.size).to eq(1)
            expect(subject.links.first.inputs).to eq({ 'name2' => 'val2' })
        end
    end

    describe '#page' do
        it 'returns a Page' do
            page = subject.page

            expect(page).to be_kind_of Arachni::Page
            expect(page.url).to eq(subject.url)
            expect(page.method).to eq(@response.request.method)
            expect(page.query_vars).to eq({ 'query_var_input' => 'query_var_val' })
            expect(page.body).to eq(@response.body)
            expect(page.response).to eq(@response)
            expect(page.paths).to eq(subject.paths)

            link = Arachni::Element::Link.new( url: @url, inputs: subject.link_vars )

            expect(page.links).to eq(subject.links | [link])
            expect(page.forms).to eq(subject.forms)
            expect(page.cookies).to eq(subject.cookies_to_be_audited)
            expect(page.headers).to eq(subject.headers)

            expect(page.cookie_jar).to eq(subject.cookie_jar)
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
            expect(subject.cookie_jar.map(&:inputs)).to eq([
                 { 'cname'               => 'cval' },
                 { 'name_from_cookiejar' => 'updated' }
            ])
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

            expect(subject.cookies_to_be_audited.map(&:inputs)).to eq([
                { 'cname'               => 'cval' },
                { 'name_from_cookiejar' => 'updated' },
                { 'irrelevant'          => 'iv' }
            ])
        end

        it 'forces the #action to the page URL' do
            cookies = subject.cookies_to_be_audited
            expect(cookies.size).to eq(2)
            expect(cookies.map { |c| c.action }.uniq).to eq([@url])
        end
    end

    describe '#text?' do
        context 'when the parser was initialized from an HTTP::Response' do
            context 'when the response is text based' do
                it { expect(subject.text?).to be_truthy }
            end

            context 'when the response is not text based' do
                let(:response) do
                    Arachni::HTTP::Response.new( url: @url, headers: {
                        'Content-Type' => 'bin/stuff'
                    })
                end
                it { expect(subject.text?).to be_falsey }
            end
        end

        context 'when the parser was initialized from a Document' do
            it 'returns true' do
                expect(from_document).to be_text
            end
        end
    end

    describe '#document' do
        context 'when the parser was initialized with an HTTP::Response' do
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
                    expect(subject.document).to be_nil
                end
            end
        end

        context 'when the parser was initialized with a Document' do
            it 'returns it' do
                expect(from_document.document). to eq document
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
                expect(subject.links.first.inputs).to eq({ 'stuff' => 'ba' })
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
                expect(subject.links).to be_empty
            end
        end
        context 'when the response is not text based' do
            let(:response) do
                Arachni::HTTP::Response.new( url: 'http://stuff', headers: {
                    'Content-Type' => 'bin/stuff'
                })
            end

            it 'returns nil' do
                expect(subject.links).to be_empty
            end

            context 'and the URL has query parameters' do
                let(:response) do
                    Arachni::HTTP::Response.new( url: @url, headers: {
                        'Content-Type' => 'bin/stuff'
                    })
                end

                it 'returns the URL parsed as a link' do
                    expect(subject.links.size).to eq(1)
                    expect(subject.links.first).to eq(subject.link)
                end
            end
        end
    end

    describe '#forms' do
        it 'returns an array of parsed forms' do
            expect(subject.forms.size).to eq(2)

            form = subject.forms.first
            expect(form.action).to eq(@utils.normalize_url( @opts.url + '/form' ))
            expect(form.url).to eq(@url)

            expect(form.inputs).to eq({
                "form_input_1" => "form_val_1",
                "form_input_2" => "form_val_2"
            })
            expect(form.method).to eq(:post)

            form = subject.forms.last
            expect(form.action).to eq(@utils.normalize_url( @opts.url + '/form_2' ))
            expect(form.url).to eq(@url)
            expect(form.inputs).to eq({ "form_2_input_1" => "form_2_val_1" })
        end

        context 'when passed secondary responses' do
            it 'identifies the nonces' do
                responses = []

                responses << Arachni::HTTP::Client.get( @opts.url + 'with_nonce', mode: :sync )
                responses << Arachni::HTTP::Client.get( @opts.url + 'with_nonce', mode: :sync )

                parser = Arachni::Parser.new( responses )
                expect(parser.forms.map { |f| f.nonce_name }.sort).to eq(%w(nonce nonce2).sort)
            end
        end
        context 'when the response is not text based' do
            let(:response) do
                Arachni::HTTP::Response.new( url: @url )
            end

            it 'returns nil' do
                expect(subject.forms).to be_empty
            end
        end
    end

    describe '#cookies' do
        it 'returns an array of cookies' do
            expect(subject.cookies.size).to eq(3)

            cookies = subject.cookies.sort_by { |cookie| cookie.name }.reverse

            cookie = cookies.pop
            expect(cookie.action).to eq(@url)
            expect(cookie.inputs).to eq({ 'cookie_input' => 'cookie_val' })
            expect(cookie.method).to eq(:get)
            expect(cookie.secure?).to be_truthy
            expect(cookie.http_only?).to be_truthy
            expect(cookie.url).to eq(@url)

            cookie = cookies.pop
            expect(cookie.action).to eq(@url)
            expect(cookie.inputs).to eq({ 'cookie_input2' => 'cookie_val2' })
            expect(cookie.method).to eq(:get)
            expect(cookie.secure?).to be_falsey
            expect(cookie.http_only?).to be_falsey
            expect(cookie.url).to eq(@url)

            cookie = cookies.pop
            expect(cookie.action).to eq(@url)
            expect(cookie.inputs).to eq({ "http_equiv_cookie_name" => "http_equiv_cookie_val" })
            expect(cookie.secure?).to be_truthy
            expect(cookie.http_only?).to be_truthy
            expect(cookie.method).to eq(:get)
            expect(cookie.url).to eq(@url)
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
                expect(link.action).to eq(response.url)
                expect(link.url).to eq(response.url)
                expect(link.inputs).to eq({
                    'param'  => 'myvalue'
                })
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
                expect(link.action).to eq(response.url + 'test2/param/myvalue')
                expect(link.url).to eq(response.url)
                expect(link.inputs).to eq({
                    'param'  => 'myvalue'
                })
            end
        end
    end

    describe '#paths' do
        context 'when it includes mailto: links' do
            let(:response) do
                Arachni::HTTP::Response.new(
                    url: @opts.url,
                    body: '
                <html>
                    <body>
                        <a href="' + @opts.url + '/test2/param/myvalue"></a>
                        <a href="mailto:name@address.com"></a>
                    </body>
                </html>'
                )
            end

            it 'ignores them' do
                expect(subject.paths).to eq([@opts.url + 'test2/param/myvalue'])
            end
        end

        context 'when an error occurs' do
            it 'returns an empty array' do
                allow(described_class).to receive(:extractors){ raise }
                expect(described_class.new( @response ).paths).to eq([])
            end
        end
    end

    context 'without base' do
        describe '#base' do
            it 'returns the response URL' do
                expect(subject.base).to eq(subject.response.url)
            end
        end

        describe '#to_absolute' do
            it 'converts a relative path to absolute' do
                expect(subject.to_absolute( 'relative/path' )).to eq(
                    @utils.normalize_url( "#{@opts.url}/relative/path" )
                )
            end
        end

        describe '#links' do
            it 'returns an array of links' do
                links = subject.links
                expect(links.size).to eq(2)

                link = links.first
                expect(link.action).to eq(@opts.url)
                expect(link.inputs).to eq({ 'query_var_input' => 'query_var_val' })
                expect(link.method).to eq(:get)
                expect(link.url).to eq(@url)

                link = links.last
                expect(link.action).to eq(@utils.normalize_url( @opts.url + '/link' ))
                expect(link.inputs).to eq({ 'link_input' => 'link_val' })
                expect(link.method).to eq(:get)
                expect(link.url).to eq(@url)
            end
        end

        describe '#paths' do
            it 'returns an array of all paths found in the page as absolute URLs' do
                paths = [
                    "link?link_input=link_val",
                    "form",
                    "form_2",
                ].map { |p| @utils.normalize_url( @opts.url.to_s + '/' + p ) }

                expect((subject.paths & paths).sort).to eq(paths.sort)
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
                expect(subject.base).to eq(@utils.normalize_url( "#{@opts.url.to_s}/this_is_the_base/" ))
            end
        end

        describe '#to_absolute' do
            it 'converts a relative path to absolute' do
                expect(subject.to_absolute( 'relative/path' )).to eq(
                    @utils.normalize_url( "#{subject.base}relative/path" )
                )
            end
        end

        describe '#links' do
            it 'returns an array of links' do
                links = subject.links
                expect(links.size).to eq(2)

                link = links.first
                expect(link.action).to eq(@opts.url + 'with_base')
                expect(link.inputs).to eq({ 'stuff' => 'ha' })
                expect(link.method).to eq(:get)
                expect(link.url).to eq(url)

                link = links.last
                expect(link.action).to eq(subject.base + 'link_with_base')
                expect(link.inputs).to eq({ 'link_input' => 'link_val' })
                expect(link.method).to eq(:get)
                expect(link.url).to eq(url)
            end
        end

        describe '#paths' do
            it 'returns an array of all paths found in the page as absolute URLs' do
                paths = [
                    '',
                    'link_with_base?link_input=link_val'
                ].map { |p| subject.base + '' + p }

                expect((subject.paths & paths).sort).to eq(paths.sort)
            end
        end
    end

    describe '#headers' do
        it 'returns an array of headers' do
            subject.headers.each { |h| expect(h.class).to eq(Arachni::Element::Header) }
        end

        it 'includes headers from the HTTP request' do
            subject.response.request.headers['X-Custom-Header'] = 'My-stuff'
            expect(subject.headers.find { |h| h.name == 'X-Custom-Header' }).to be_truthy
        end

        it "excludes #{Arachni::HTTP::Client::SEED_HEADER_NAME}" do
            subject.response.request.headers[Arachni::HTTP::Client::SEED_HEADER_NAME] = 'My-stuff'
            expect(subject.headers.find { |h| h.name == Arachni::HTTP::Client::SEED_HEADER_NAME }).to be_falsey
        end

        it 'excludes Content-Type' do
            subject.response.request.headers['Content-Length'] = '123'
            expect(subject.headers.find { |h| h.name == 'Content-Length' }).to be_falsey
        end
    end

    describe '#link_vars' do
        it 'returns a hash of link query inputs' do
            expect(subject.link_vars).to eq({ 'query_var_input' => 'query_var_val' })
        end

        context "when there are #{Arachni::OptionGroups::Scope}#url_rewrites" do
            before :each do
                Arachni::Options.scope.url_rewrites = {
                    'stuff\/(\d+)' => '/stuff?id=\1'
                }
            end

            let(:response) do
                Arachni::HTTP::Client.get( "#{@opts.url}/stuff/13", mode: :sync )
            end

            it 'rewrites the url' do
                expect(subject.link_vars).to eq({ 'id' => '13' })
            end
        end

        context 'when the URL cannot be parsed' do
            it 'returns an empty array' do
                subject.url = nil
                expect(subject.link_vars).to eq({})
            end
        end
    end

    describe '.markup?' do
        context 'when dealing with markup' do
            it 'returns true' do
                expect(described_class.markup?( '<stuff></stuff>' )).to be_truthy
            end
        end

        context 'when not dealing with markup' do
            it 'returns false' do
                expect(described_class.markup?( 'stuff' )).to be_falsey
            end

            context 'but includes markup' do
                it 'returns false' do
                    s = { test: '<stuff></stuff>' }.to_json
                    expect(described_class.markup?( s )).to be_falsey

                    expect(described_class.markup?( 'blah <stuff></stuff>' )).to be_falsey
                end

                context 'and begins with a doctype' do
                    it 'returns false' do
                        s = { test: '<stuff></stuff>' }.to_json
                        s = "<!DOCTYPE html>#{s}"

                        expect(described_class.markup?( s )).to be_falsey
                    end
                end
            end
        end
    end
end
