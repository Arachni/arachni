require 'spec_helper'

describe Arachni::Page do

    def create_page( options = {} )
        described_class.new response: Arachni::HTTP::Response.new(
            request: Arachni::HTTP::Request.new(
                         'http://a-url.com/',
                         method: :get,
                         headers: {
                             'req-header-name' => 'req header value'
                         }
                     ),

            code:    200,
            url:     'http://a-url.com/?myvar=my%20value',
            body:    options[:body],
            headers: options[:headers]
        )
    end

    let( :response ) do
        body = <<-EOHTML
                <a href="http://a-url.com/path?var1=1">1</a>
                <a href="http://a-url.com/a/path?var2=2">2</a>
                <a href="http://a-url.com/another/path/?var3=3">3</a>

                <form> <input name=""/> </form>
        EOHTML

        Arachni::HTTP::Response.new(
            request: Arachni::HTTP::Request.new(
                         'http://a-url.com/',
                         method: :get,
                         headers: {
                             'req-header-name' => 'req header value'
                         }
                     ),

            code:    200,
            url:     'http://a-url.com/?myvar=my%20value',
            body:    body,
            headers: {
                'res-header-name' => 'res header value',
                'Set-Cookie'      => 'cookiename=cokie+value'
            }
        )
    end
    let( :page ){ described_class.new( response: response ) }

    describe '#initialize' do
        describe 'option' do
            describe :response do
                it 'uses it to populate the page data' do
                    page   = described_class.new( response: response )
                    parser = Arachni::Parser.new( response )

                    page.url.should == parser.url
                    page.method.should == parser.response.request.method
                    page.response.should == parser.response
                    page.body.should == parser.response.body
                    page.query_vars.should == parser.link_vars
                    page.paths.should == parser.paths
                    page.links.should == parser.links
                    page.forms.should == parser.forms
                    page.cookies.should == parser.cookies_to_be_audited
                    page.headers.should == parser.headers
                    page.cookiejar.should == parser.cookie_jar
                    page.text?.should == parser.text?
                end
            end

            describe :parser do
                it 'uses it to populate the page data' do
                    parser = Arachni::Parser.new( response )
                    page   = described_class.new( parser: parser )

                    page.url.should == parser.url
                    page.method.should == parser.response.request.method
                    page.response.should == parser.response
                    page.body.should == parser.response.body
                    page.query_vars.should == parser.link_vars
                    page.paths.should == parser.paths
                    page.links.should == parser.links
                    page.forms.should == parser.forms
                    page.cookies.should == parser.cookies_to_be_audited
                    page.headers.should == parser.headers
                    page.cookiejar.should == parser.cookie_jar
                    page.text?.should == parser.text?
                end
            end
        end

        context 'when called without options' do
            it 'raises ArgumentError' do
                expect{ described_class.new }.to raise_error ArgumentError
            end
        end
    end

    describe '#dom_body=' do
        it 'overrides the body of the HTTP response for the parsing process' do
            url = 'http://stuff.com/'
            page = Arachni::HTTP::Response.new(
                url: url,
                body: '<a href="/?name=val">Stuff</a>',
                request: Arachni::HTTP::Request.new( url )
            ).to_page

            page.dom_body = '<a href="/?name2=val2">Stuff</a>'
            page.links.size.should == 1
            page.links.first.inputs.should == { 'name2' => 'val2' }
        end

        it 'clears the existing element cache' do
            url = 'http://stuff.com/'
            page = Arachni::HTTP::Response.new(
                url: url,
                body: '<a href="/?name=val">Stuff</a>',
                request: Arachni::HTTP::Request.new( url )
            ).to_page

            page.links.size.should == 1
            page.links.first.inputs.should == { 'name' => 'val' }

            page.dom_body = '<a href="/?name2=val2">Stuff</a>'
            page.links.size.should == 1
            page.links.first.inputs.should == { 'name2' => 'val2' }
        end
    end

    describe '#links=' do
        it 'sets the page links' do
            page.links.should be_any
            page.links = []
            page.links.should be_empty
        end
    end

    describe '#forms=' do
        it 'sets the page forms' do
            page.forms.should be_any
            page.forms = []
            page.forms.should be_empty
        end
    end

    describe '#cookies=' do
        it 'sets the page cookies' do
            page.cookies.should be_any
            page.cookies = []
            page.cookies.should be_empty
        end
    end

    describe '#headers=' do
        it 'sets the page links' do
            page.headers.should be_any
            page.headers = []
            page.headers.should be_empty
        end
    end

    describe '#platforms' do
        it 'returns platforms for the given page' do
            page.platforms.should be_kind_of Arachni::Platform::Manager
        end
    end

    describe '#has_javascript?' do
        context 'when the page has JavaScript code' do
            it 'returns true' do
                create_page( body: '<Script>var i = '';</script>' ).
                    has_javascript?.should be_true
            end
        end
        context 'when the page does not have JavaScript code' do
            it 'returns false' do
                create_page( body: 'stuff' ).
                    has_javascript?.should be_false
            end
        end
    end

    describe '#text?' do
        context 'when the HTTP response was text based' do
            it 'returns true' do
                res = Arachni::HTTP::Response.new(
                    url: 'http://test.com',
                    body: '',
                    request: Arachni::HTTP::Request.new( 'http://test.com' ),
                    headers: {
                       'Content-Type' => 'text/html',
                       'Set-Cookie'   => 'cname=cval'
                   }
                )
                Arachni::Parser.new( res ).page.text?.should be_true
            end
        end

        context 'when the response is not text based' do
            it 'returns false' do
                res = Arachni::HTTP::Response.new(
                    url:     'http://test.com',
                    headers: {
                        'Content-Type' => 'stuff/bin'
                    },
                    request: Arachni::HTTP::Request.new( 'http://test.com' )
                )
                Arachni::Parser.new( res ).page.text?.should be_false
            end
        end
    end

    describe '#==' do
        context 'when the pages are different' do
            it 'returns false' do
                p = create_page( body: 'stuff here' )
                p.links << Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )
                p.forms << Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )
                p.cookies << Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )

                c = p.dup
                c.body << 'test'
                c.should_not == p

                c = p.dup
                c.links << Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                c.should_not == p

                c = p.dup
                c.forms << Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                c.should_not == p

                c = p.dup
                c.cookies << Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                c.should_not == p
            end
        end
        context 'when the pages are identical' do
            it 'returns true' do
                p = create_page( body: 'stuff here')
                p.links << Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )
                p.forms << Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )
                p.cookies << Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )

                c = p.dup
                c.should == p

                c = p.dup
                p.body << 'test'
                p.links << Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                p.forms << Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                p.cookies << Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )

                c.body << 'test'
                c.links << Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                c.forms << Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                c.cookies << Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                c.should == p
            end
        end
    end

    describe '#eql?' do
        context 'when the pages are different' do
            it 'returns false' do
                p = create_page( body: 'stuff here')
                p.links << Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )
                p.forms << Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )
                p.cookies << Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )

                c = p.dup
                c.body << 'test'
                c.should_not eql p

                c = p.dup
                c.links << Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                c.should_not eql p

                c = p.dup
                c.forms << Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                c.should_not eql p

                c = p.dup
                c.cookies << Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                c.should_not eql p
            end
        end
        context 'when the pages are identical' do
            it 'returns true' do
                p = create_page( body: 'stuff here')
                p.links << Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )
                p.forms << Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )
                p.cookies << Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )

                c = p.dup
                c.should eql p

                c = p.dup
                p.body << 'test'
                p.links << Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                p.forms << Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                p.cookies << Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )

                c.body << 'test'
                c.links << Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                c.forms << Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                c.cookies << Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )
                c.should eql p
            end
        end
    end

    describe '#title' do
        context 'when the page has a title' do
            it 'returns the page title' do
                title = 'Stuff here'
                create_page( body: "<title>#{title}</title>" ).title.should == title
                create_page( body: '<title></title>' ).title.should == ''
            end
        end
        context 'when the page does not have a title' do
            it 'returns nil' do
                create_page.title.should be_nil
                create_page( body: '' ).title.should be_nil
            end
        end
    end

    describe '#elements' do
        it 'returns all page elemenrs' do
            page.elements.should == (page.links | page.forms | page.cookies | page.headers)
        end
    end

    describe '.from_data' do
        it 'creates a page from the given data' do
            elem_opts = {
                url: 'http://test.com',
                inputs: { 'test' => 'stuff' }
            }

            data = {
                url:  'http://test/',
                body: 'test',
                paths: [ 'http://test/1', 'http://test/2' ],
                links: [Arachni::Element::Link.new( elem_opts )],
                forms: [Arachni::Element::Form.new( elem_opts )],
                cookies: [Arachni::Element::Cookie.new( elem_opts )],
                cookiejar: [
                    Arachni::Element::Cookie.new( elem_opts ),
                    Arachni::Element::Cookie.new( elem_opts )
                ],
                headers: [Arachni::Element::Header.new( elem_opts )],
                response: {
                    code: 200
                }
            }

            page = Arachni::Page.from_data( data )
            page.code.should == data[:response][:code]
            page.url.should == data[:url]
            page.body.should == data[:body]
            page.paths.should == data[:paths]

            page.links.should == data[:links]
            page.forms.should == data[:forms]
            page.cookies.should == data[:cookies]
            page.headers.should == data[:headers]

            page.cookiejar.should == data[:cookiejar]

            page.response.code.should == data[:response][:code]
            page.response.url.should == data[:url]
            page.response.body.should == data[:body]
            page.response.request.url.should == data[:url]
        end

        context 'when no HTTP data is given' do
            it 'creates them with default values' do
                data = {
                    url:  'http://test/',
                    body: 'test'
                }

                page = Arachni::Page.from_data( data )
                page.url.should == data[:url]
                page.body.should == data[:body]
                page.code.should == 200

                page.links.should == []
                page.forms.should == []
                page.cookies.should == []
                page.headers.should == []

                page.cookiejar.should == []

                page.response.code.should == 200
                page.response.url.should == data[:url]
                page.response.body.should == data[:body]
                page.response.request.url.should == data[:url]
            end
        end
    end

    describe '.from_response' do
        it 'creates a page from an HTTP response' do
            page = Arachni::Page.from_response( response )
            page.class.should == Arachni::Page
            parser = Arachni::Parser.new( response )

            page.url.should == parser.url
            page.method.should == parser.response.request.method
            page.response.should == parser.response
            page.body.should == parser.response.body
            page.query_vars.should == parser.link_vars
            page.paths.should == parser.paths
            page.links.should == parser.links
            page.forms.should == parser.forms
            page.cookies.should == parser.cookies_to_be_audited
            page.headers.should == parser.headers
            page.cookiejar.should == parser.cookie_jar
            page.text?.should == parser.text?

        end
    end

end
