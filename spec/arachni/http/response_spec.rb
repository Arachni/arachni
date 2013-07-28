require 'spec_helper'

describe Arachni::HTTP::Response do
    it_should_behave_like 'Arachni::HTTP::Message'

    describe '#redirection?' do
        context 'when the response is a redirection' do
            it 'returns true' do
                300.upto( 399 ) do |c|
                    described_class.new(
                        url:     'http://test.com',
                        code:    c,
                        headers: {
                            location: '/test'
                        }).redirection?.should be_true
                end
            end
        end

        context 'when the response is not a redirection' do
            it 'returns false' do
                described_class.new( 'http://test.com', code: 200 ).redirection?.should be_false
            end
        end
    end

    describe '#text?' do
        context 'when the content-type is' do
            context 'text/*' do
                it 'returns true' do
                    h = {
                        headers: { 'Content-Type' => 'text/stuff' },
                        body:    'stuff'
                    }
                    described_class.new( 'http://test.com', h ).text?.should be_true
                end
            end

            context 'application/*' do
                context 'and the response body is' do
                    context 'binary' do
                        it 'returns false' do
                            h = {
                                headers: { 'Content-Type' => 'application/stuff' },
                                body:    "\00\00\00"
                            }
                            described_class.new( 'http://test.com', h ).text?.should be_false
                        end
                    end

                    context 'text' do
                        it 'returns true' do
                            h = {
                                headers: { 'Content-Type' => 'application/stuff' },
                                body:    'stuff'
                            }
                            described_class.new( 'http://test.com', h ).text?.should be_true
                        end
                    end
                end
            end

            context 'other' do
                it 'returns false' do
                    h = {
                        headers: { 'Content-Type' => 'blah/stuff' },
                        body:    'stuff'
                    }
                    described_class.new( 'http://test.com', h ).text?.should be_false
                end
            end

            context nil do
                context 'and the response body is' do
                    context 'binary' do
                        it 'returns false' do
                            h = { body: "\00\00\00" }
                            described_class.new( 'http://test.com', h ).text?.should be_false
                        end
                    end

                    context 'text' do
                        it 'returns true' do
                            h = { body: 'stuff' }
                            described_class.new( 'http://test.com', h ).text?.should be_true
                        end
                    end
                end
            end
        end
    end

    describe '#to_page' do
        it 'returns an Arachni::Page based on the response data' do
            body = <<-EOHTML
                <a href="http://a-url.com/path?var1=1">1</a>
                <a href="http://a-url.com/a/path?var2=2">2</a>
                <a href="http://a-url.com/another/path/?var3=3">3</a>
            EOHTML

            response = described_class.new(
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

            parser = Arachni::Parser.new( response )
            page = parser.page

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

    describe '#==' do
        context 'when responses are identical' do
            it 'returns true' do
                h = {
                    headers: { 'Content-Type' => 'application/stuff' },
                    body:    'stuff'
                }
                described_class.new( 'http://test.com', h.dup ).should ==
                    described_class.new( 'http://test.com', h.dup )
            end
        end
        context 'when responses are not identical' do
            it 'returns false' do
                described_class.new(
                    'http://test.com',
                    headers: { 'Content-Type' => 'application/stuff' },
                    body:    'stuff'
                ).should_not ==
                    described_class.new(
                        'http://test.com',
                        headers: { 'Content-Type' => 'application/stuff1' },
                        body:    'stuff'
                    )
            end
        end
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            h = {
                version:        '1.1',
                url:            'http://stuff.com/',
                code:           200,
                ip_address:     '10.0.0.1',
                headers:        { 'Content-Type' => 'test/html' },
                headers_string: 'HTTP/1.1 200 OK',
                body:           'stuff',
                time:           1.2,
                total_time:     2.2,
                return_code:    :ok,
                return_message: 'No error'
            }

            described_class.new( h ).to_h.should == h.stringify_keys
        end
    end

end
