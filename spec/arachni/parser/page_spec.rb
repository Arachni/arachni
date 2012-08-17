require_relative '../../spec_helper'

describe Arachni::Parser::Page do
    before( :all ) do
        @page_data = {
            url: 'http://a-url.com/',
            code: 200,
            method: 'get',
            query_vars: {
                'myvar' => 'my value'
            },
            body: 'some html code',
            response_headers: {
                'header-name' => 'header value'
            },
            paths: [
                'http://a-url.com/path',
                'http://a-url.com/a/path',
                'http://a-url.com/another/path/'
            ],
            links: [],
            forms: [],
            cookies: [],
            headers: [],
            cookiejar: {
                'cookiename' => 'cokie value'
            }
        }

        @opts = Arachni::Options.instance
        @opts.audit_links = true
        @opts.audit_forms = true
        @opts.audit_cookies = true
        @opts.audit_headers = true

        @page = Arachni::Parser::Page.new( @page_data )
        @empty_page = Arachni::Parser::Page.new
    end

    describe '#text?' do
        context 'when the HTTP response was text based' do
            it 'should return true' do
                res = Typhoeus::Response.new(
                    effective_url: 'http://test.com',
                    body: '',
                    headers_hash: {
                       'Content-Type' => 'text/html',
                       'Set-Cookie'   => 'cname=cval'
                   }
                )
                Arachni::Parser.new( res, @opts ).page.text?.should be_true
            end
        end

        context 'when the response is not text based' do
            it 'should return false' do
                res = Typhoeus::Response.new( effective_url: 'http://test.com' )
                Arachni::Parser.new( res, @opts ).page.text?.should be_false
            end
        end
    end

    describe '#==' do
        context 'when the pages are different' do
            it 'should return false' do
                p = Arachni::Parser::Page.new( body: 'stuff here')
                p.links << Arachni::Parser::Element::Link.new( 'http://test.com', 'test' => 'stuff' )
                p.forms << Arachni::Parser::Element::Form.new( 'http://test.com', 'test' => 'stuff' )
                p.cookies << Arachni::Parser::Element::Cookie.new( 'http://test.com', 'test' => 'stuff' )
                p.headers << Arachni::Parser::Element::Header.new( 'http://test.com', 'test' => 'stuff' )

                c = p.dup
                c.body << 'test'
                c.should_not == p

                c = p.dup
                c.links << Arachni::Parser::Element::Link.new( 'http://test.com', 'test' => 'stuff2' )
                c.should_not == p

                c = p.dup
                c.forms << Arachni::Parser::Element::Form.new( 'http://test.com', 'test' => 'stuff2' )
                c.should_not == p

                c = p.dup
                c.cookies << Arachni::Parser::Element::Cookie.new( 'http://test.com', 'test' => 'stuff2' )
                c.should_not == p

                c = p.dup
                c.headers << Arachni::Parser::Element::Header.new( 'http://test.com', 'test' => 'stuff2' )
                c.should_not == p
            end
        end
        context 'when the pages are identical' do
            it 'should return true' do
                p = Arachni::Parser::Page.new( body: 'stuff here')
                p.links << Arachni::Parser::Element::Link.new( 'http://test.com', 'test' => 'stuff' )
                p.forms << Arachni::Parser::Element::Form.new( 'http://test.com', 'test' => 'stuff' )
                p.cookies << Arachni::Parser::Element::Cookie.new( 'http://test.com', 'test' => 'stuff' )
                p.headers << Arachni::Parser::Element::Header.new( 'http://test.com', 'test' => 'stuff' )

                c = p.dup
                c.should == p

                c = p.dup
                p.body << 'test'
                p.links << Arachni::Parser::Element::Link.new( 'http://test.com', 'test' => 'stuff2' )
                p.forms << Arachni::Parser::Element::Form.new( 'http://test.com', 'test' => 'stuff2' )
                p.cookies << Arachni::Parser::Element::Cookie.new( 'http://test.com', 'test' => 'stuff2' )
                p.headers << Arachni::Parser::Element::Header.new( 'http://test.com', 'test' => 'stuff2' )

                c.body << 'test'
                c.links << Arachni::Parser::Element::Link.new( 'http://test.com', 'test' => 'stuff2' )
                c.forms << Arachni::Parser::Element::Form.new( 'http://test.com', 'test' => 'stuff2' )
                c.cookies << Arachni::Parser::Element::Cookie.new( 'http://test.com', 'test' => 'stuff2' )
                c.headers << Arachni::Parser::Element::Header.new( 'http://test.com', 'test' => 'stuff2' )
                c.should == p
            end
        end
    end

    describe '#eql?' do
        context 'when the pages are different' do
            it 'should return false' do
                p = Arachni::Parser::Page.new( body: 'stuff here')
                p.links << Arachni::Parser::Element::Link.new( 'http://test.com', 'test' => 'stuff' )
                p.forms << Arachni::Parser::Element::Form.new( 'http://test.com', 'test' => 'stuff' )
                p.cookies << Arachni::Parser::Element::Cookie.new( 'http://test.com', 'test' => 'stuff' )
                p.headers << Arachni::Parser::Element::Header.new( 'http://test.com', 'test' => 'stuff' )

                c = p.dup
                c.body << 'test'
                c.should_not eql p

                c = p.dup
                c.links << Arachni::Parser::Element::Link.new( 'http://test.com', 'test' => 'stuff2' )
                c.should_not eql p

                c = p.dup
                c.forms << Arachni::Parser::Element::Form.new( 'http://test.com', 'test' => 'stuff2' )
                c.should_not eql p

                c = p.dup
                c.cookies << Arachni::Parser::Element::Cookie.new( 'http://test.com', 'test' => 'stuff2' )
                c.should_not eql p

                c = p.dup
                c.headers << Arachni::Parser::Element::Header.new( 'http://test.com', 'test' => 'stuff2' )
                c.should_not eql p
            end
        end
        context 'when the pages are identical' do
            it 'should return true' do
                p = Arachni::Parser::Page.new( body: 'stuff here')
                p.links << Arachni::Parser::Element::Link.new( 'http://test.com', 'test' => 'stuff' )
                p.forms << Arachni::Parser::Element::Form.new( 'http://test.com', 'test' => 'stuff' )
                p.cookies << Arachni::Parser::Element::Cookie.new( 'http://test.com', 'test' => 'stuff' )
                p.headers << Arachni::Parser::Element::Header.new( 'http://test.com', 'test' => 'stuff' )

                c = p.dup
                c.should eql p

                c = p.dup
                p.body << 'test'
                p.links << Arachni::Parser::Element::Link.new( 'http://test.com', 'test' => 'stuff2' )
                p.forms << Arachni::Parser::Element::Form.new( 'http://test.com', 'test' => 'stuff2' )
                p.cookies << Arachni::Parser::Element::Cookie.new( 'http://test.com', 'test' => 'stuff2' )
                p.headers << Arachni::Parser::Element::Header.new( 'http://test.com', 'test' => 'stuff2' )

                c.body << 'test'
                c.links << Arachni::Parser::Element::Link.new( 'http://test.com', 'test' => 'stuff2' )
                c.forms << Arachni::Parser::Element::Form.new( 'http://test.com', 'test' => 'stuff2' )
                c.cookies << Arachni::Parser::Element::Cookie.new( 'http://test.com', 'test' => 'stuff2' )
                c.headers << Arachni::Parser::Element::Header.new( 'http://test.com', 'test' => 'stuff2' )
                c.should eql p
            end
        end
    end

    describe '#title' do
        context 'when the page has a title' do
            it 'should return the page title' do
                title = 'Stuff here'
                Arachni::Parser::Page.new( body: "<title>#{title}</title>").title.should == title

                Arachni::Parser::Page.new( body: "<title></title>").title.should == ''
            end
        end
        context 'when the page does not have a title' do
            it 'should return nil' do
                Arachni::Parser::Page.new.title.should be_nil
                Arachni::Parser::Page.new( body: "" ).title.should be_nil
            end
        end
    end

    context 'when called with options' do
        it 'should retain its options' do
            @page_data.each do |k, v|
                @page.instance_variable_get( "@#{k}".to_sym ).should == v
            end
        end

        describe '#document' do
            it 'should return a parsed tree' do
                @page.document.to_html.should == Nokogiri::HTML( @page.body ).to_html
            end
        end

        describe '#to_hash' do
            it 'should return a hash representation' do
                @page.to_hash.should == @page_data
            end
        end
    end

    context 'when called without options' do
        describe '#links' do
            it 'should default to empty array' do
                @empty_page.links.should == []
            end
        end

        describe '#forms' do
            it 'should default to empty array' do
                @empty_page.forms.should == []
            end
        end

        describe '#cookies' do
            it 'should default to empty array' do
                @empty_page.cookies.should == []
            end
        end

        describe '#headers' do
            it 'should default to empty array' do
                @empty_page.headers.should == []
            end
        end

        describe '#cookiejar' do
            it 'should default to empty hash' do
                @empty_page.cookiejar.should == {}
            end
        end

        describe '#paths' do
            it 'should default to empty array' do
                @empty_page.paths.should == []
            end
        end

        describe '#response_headers' do
            it 'should default to empty array' do
                @empty_page.paths.should == []
            end
        end

        describe '#query_vars' do
            it 'should default to empty hash' do
                @empty_page.query_vars.should == {}
            end
        end

        describe '#body' do
            it 'should default to empty string' do
                @empty_page.body.should == ''
            end
        end

        describe '#document' do
            it 'should return a parsed tree' do
                @empty_page.document.to_html.should == Nokogiri::HTML( @empty_page.body ).to_html
            end
        end
    end

    describe '.from_http_response' do
        it 'should return a page from an HTTP response and opts' do
            res = Typhoeus::Response.new( effective_url: 'http://url.com' )
            page = Arachni::Parser::Page.from_http_response( res, Arachni::Options.instance )
            page.class.should == Arachni::Parser::Page
        end
    end

end
