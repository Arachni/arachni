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
                res = Arachni::HTTP::Response.new( url: 'http://test.com',
                                              request: Arachni::HTTP::Request.new( 'http://test.com' ), )
                Arachni::Parser.new( res ).page.text?.should be_false
            end
        end
    end

    describe '#==' do
        context 'when the bodies or headers are different' do
            it 'returns false' do
                create_page( body: '1body' ).should_not == create_page( body: 'body' )
                create_page( headers: { '1' => '1'} ).should_not == create_page( headers: { '1' => '2'} )
                create_page( body: 'body', headers: { '1' => '1'} ).should_not == create_page( body: 'body', headers: { '1' => '2'} )
            end
        end

        context 'when the bodies and headers are identical' do
            it 'returns true' do
                create_page( body: 'body' ).should == create_page( body: 'body' )
                create_page( headers: { '1' => '1'} ).should == create_page( headers: { '1' => '1'} )
                create_page( body: 'body', headers: { '1' => '1'} ).should == create_page( body: 'body', headers: { '1' => '1'} )
            end
        end
    end

    describe '#eql?' do
        context 'when the bodies or headers are different' do
            it 'returns false' do
                create_page( body: '1body' ).should_not eq create_page( body: 'body' )
                create_page( headers: { '1' => '1'} ).should_not eq create_page( headers: { '1' => '2'} )
                create_page( body: 'body', headers: { '1' => '1'} ).should_not eq create_page( body: 'body', headers: { '1' => '2'} )
            end
        end
        context 'when the bodies and headers are identical' do
            it 'returns true' do
                create_page( body: 'body' ).should eq create_page( body: 'body' )
                create_page( headers: { '1' => '1'} ).should eq create_page( headers: { '1' => '1'} )
                create_page( body: 'body', headers: { '1' => '1'} ).should eq create_page( body: 'body', headers: { '1' => '1'} )
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
            data = {
                url:  'http://test/',
                body: 'test',
                paths: [ 'http://test/1', 'http://test/2' ],
                links: [ Arachni::Element::Link.new( 'http://test.com', 'test' => 'stuff' ) ],
                forms: [Arachni::Element::Form.new( 'http://test.com', 'test' => 'stuff' )],
                cookies: [Arachni::Element::Cookie.new( 'http://test.com', 'test' => 'stuff' )],
                cookiejar: [
                    Arachni::Element::Cookie.new( 'http://test.com', 'test' => 'stuff' ),
                    Arachni::Element::Cookie.new( 'http://test.com', 'test1' => 'stuff1' )
                ],
                headers: [Arachni::Element::Header.new( 'http://test.com', 'test' => 'stuff' )],
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
