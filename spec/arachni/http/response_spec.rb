# encoding: utf-8
require 'spec_helper'

describe Arachni::HTTP::Response do
    it_should_behave_like 'Arachni::HTTP::Message'

    before( :all ) do
        @http    = Arachni::HTTP::Client
        @url     = web_server_url_for( :client )
        @subject = @http.get( @url, mode: :sync )
    end
    let(:url) { 'http://test.com' }
    subject { @subject }

    it "supports #{Arachni::RPC::Serializer}" do
        expect(subject).to eq(Arachni::RPC::Serializer.deep_clone( subject ))
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        %w(url code ip_address headers body time app_time total_time return_code
            return_message).each do |attribute|
            it "includes '#{attribute}'" do
                expect(data[attribute]).to eq(subject.send( attribute ))
            end
        end

        it "includes 'request'" do
            expect(data['request']).to eq(subject.request.to_rpc_data)
        end

        it "does not include 'scope" do
            expect(data).not_to include 'scope'
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(url code ip_address headers body time app_time total_time return_code
            return_message request).each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored.send( attribute )).to eq(subject.send( attribute ))
            end
        end
    end

    describe '#status_line' do
        it 'returns the first line of the response' do
            expect(@http.get( @url, mode: :sync ).status_line).to eq('HTTP/1.1 200 OK')
        end
    end

    describe '#modified?' do
        context 'when the #code is' do
            describe '200' do
                it 'returns false' do
                    expect(described_class.new( url: @url, code: 200 )).to be_modified
                end
            end

            describe '304' do
                it 'returns true' do
                    expect(described_class.new( url: @url, code: 304 )).not_to be_modified
                end
            end
        end
    end

    describe '#redirection?' do
        context 'when the response is a redirection' do
            it 'returns true' do
                300.upto( 399 ) do |c|
                    expect(described_class.new(
                        url:     'http://test.com',
                        code:    c,
                        headers: {
                            location: '/test'
                        }).redirection?).to be_truthy
                end
            end
        end

        context 'when the response is not a redirection' do
            it 'returns false' do
                expect(described_class.new( url: 'http://test.com', code: 200 ).redirection?).to be_falsey
            end
        end
    end

    describe '#to_s' do
        it 'returns the HTTP response as a string' do
            expect(subject.to_s).to eq("#{subject.headers_string}#{subject.body}")
        end
    end

    describe '#platforms' do
        it 'returns the platform manager for the resource' do
            expect(Factory[:response].platforms).to be_kind_of Arachni::Platform::Manager
        end
    end

    describe '#app_time' do
        it 'returns the approximated webap pprocessing time' do
            response = @http.get( @url, mode: :sync )
            expect(response.app_time).to be > 0
            expect(response.app_time).to be < 0.01

            response = @http.get( "#{@url}/sleep", mode: :sync )
            expect(response.app_time).to be > 5
            expect(response.app_time).to be < 5.01
        end
    end

    describe '#ok?' do
        before do
            subject.return_code = return_code
        end

        context 'when #return_code is' do
            context ':ok' do
                let(:return_code) { :ok }

                expect_it { to be_ok }
            end

            context 'not :ok' do
                let(:return_code) { :blah }

                expect_it { to_not be_ok }
            end

            context 'missing' do
                let(:return_code) { nil }

                expect_it { to be_ok }
            end
        end
    end

    describe '#html?' do
        context 'when it starts with an HTML doctype' do
            subject do
                described_class.new(
                    url:  'http://test.com',
                    code: 200,
                    body: body
                )
            end

            let(:body) { '<!DOCTYPE html' }

            expect_it { to be_html }
        end

        context 'when the Content-Type is' do
            subject do
                described_class.new(
                    url:     'http://test.com',
                    code:    200,
                    headers: {
                        'Content-Type' => content_type
                    }
                )
            end

            ['text/html', 'text/html; charset=ISO-8859-1',
             'text/html ; charset=ISO-8859-1',
             'application/xhtml+xml', 'application/xhtml+xml; charset=ISO-8859-1',
             'application/xhtml+xml ; charset=ISO-8859-1'].each do |content_type|

                context content_type.downcase do
                    let(:content_type) { content_type.downcase }

                    expect_it { to be_html }
                end

                context content_type.upcase do
                    let(:content_type) { content_type.upcase }

                    expect_it { to be_html }
                end
            end

            context 'other' do
                let(:content_type) { 'text/plain' }

                expect_it { to_not be_html }
            end

            context 'missing' do
                context 'and X-Content-Type-Options is' do
                    context 'missing' do
                        context 'and the body includes HTML identifier' do
                            subject do
                                described_class.new(
                                    url:  'http://test.com',
                                    code: 200,
                                    body: body
                                )
                            end

                            described_class::HTML_IDENTIFIERS.each do |id|
                                context id.downcase do
                                    let(:body) { id.downcase }

                                    expect_it { to be_html }
                                end

                                context id.upcase do
                                    let(:body) { id.upcase }

                                    expect_it { to be_html }
                                end
                            end

                            context 'other' do
                                let(:body) { 'Stuff here' }

                                expect_it { to_not be_html }
                            end
                        end
                    end

                    context 'nosniff' do
                        context 'and the body includes HTML identifier' do
                            subject do
                                described_class.new(
                                    url:  'http://test.com',
                                    code: 200,
                                    body: body,
                                    headers: {
                                        'X-Content-Type-Options' => 'nosniff'
                                    }
                                )
                            end

                            described_class::HTML_IDENTIFIERS.each do |id|
                                context id.downcase do
                                    let(:body) { id.downcase }

                                    expect_it { to_not be_html }
                                end

                                context id.upcase do
                                    let(:body) { id.upcase }

                                    expect_it { to_not be_html }
                                end
                            end

                            context 'other' do
                                let(:body) { 'Stuff here' }

                                expect_it { to_not be_html }
                            end
                        end
                    end
                end

            end
        end

    end

    describe '#partial?' do
        context 'when the response body does not match the content-lenth' do
            it 'returns true' do
                response = @http.get( "#{@url}/partial", mode: :sync )
                expect(response).to be_partial
            end
        end

        context 'when the response body matches the content-length' do
            it 'returns false' do
                response = @http.get( @url, mode: :sync )
                expect(response).to_not be_partial
            end
        end

        context 'when dealing with a stream' do
            context 'that does not complete' do
                it 'returns true' do
                    response = @http.get( "#{@url}/partial_stream", mode: :sync )
                    expect(response.return_code).to eq :partial_file
                    expect(response).to be_partial
                end
            end

            context 'that closes abruptly' do
                it 'returns true' do
                    response = @http.get( "#{@url}/fail_stream", mode: :sync )
                    expect(response.return_code).to eq :recv_error
                    expect(response).to be_partial
                end
            end

            context 'that completes' do
                it 'returns false' do
                    response = @http.get( "#{@url}/stream", mode: :sync )
                    expect(response).to_not be_partial
                end
            end
        end
    end

    describe '#text?' do
        context 'when the content-type is' do
            context 'text/*' do
                it 'returns true' do
                    h = {
                        url:     'http://test.com',
                        headers: { 'Content-Type' => 'text/stuff' },
                        body:    'stuff'
                    }
                    expect(described_class.new( h ).text?).to be_truthy
                end
            end

            context 'application/*' do
                context 'and the response body is' do
                    context 'binary' do
                        it 'returns false' do
                            h = {
                                url:     'http://test.com',
                                headers: { 'Content-Type' => 'application/stuff' },
                                body:    "\00\00\00"
                            }
                            expect(described_class.new( h ).text?).to be_falsey
                        end
                    end

                    context 'text' do
                        it 'returns true' do
                            h = {
                                url:     'http://test.com',
                                headers: { 'Content-Type' => 'application/stuff' },
                                body:    'stuff'
                            }
                            expect(described_class.new( h ).text?).to be_truthy
                        end
                    end
                end
            end

            context 'other' do
                it 'returns false' do
                    h = {
                        url:     'http://test.com',
                        headers: { 'Content-Type' => 'blah/stuff' },
                        body:    'stuff'
                    }
                    expect(described_class.new( h ).text?).to be_falsey
                end
            end

            context 'nil' do
                context 'and the response body is' do
                    context 'binary' do
                        it 'returns false' do
                            h = {
                                url:  'http://test.com',
                                body: "\00\00\00"
                            }
                            expect(described_class.new( h ).text?).to eq(false)
                        end
                    end

                    context 'text' do
                        it 'returns true' do
                            h = {
                                url:  'http://test.com',
                                body: 'stuff'
                            }
                            expect(described_class.new( h ).text?).to eq(true)
                        end
                    end

                    context 'inconclusive' do
                        it 'returns nil' do
                            r = described_class.new(
                                url:  'http://test.com',
                                body: "abc\u3042\x81"
                            )
                            expect(r.text?).to be_nil
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
                             url:    'http://a-url.com/',
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

            expect(page.url).to eq(parser.url)
            expect(page.method).to eq(parser.response.request.method)
            expect(page.response).to eq(parser.response)
            expect(page.body).to eq(parser.response.body)
            expect(page.query_vars).to eq(parser.link_vars)
            expect(page.paths).to eq(parser.paths)
            expect(page.links).to eq(parser.links)
            expect(page.forms).to eq(parser.forms)
            expect(page.cookies).to eq(parser.cookies_to_be_audited)
            expect(page.headers).to eq(parser.headers)
            expect(page.cookie_jar).to eq(parser.cookie_jar)
            expect(page.text?).to eq(parser.text?)
        end
    end

    describe '#time=' do
        it 'sets the #time' do
            r = described_class.new( url: url )
            r.time = 1.2
            expect(r.time).to eq(1.2)
        end

        it 'casts to Float' do
            r = described_class.new( url: url )
            r.time = '1.2'
            expect(r.time).to eq(1.2)
        end
    end

    describe '#time' do
        it 'defaults to 0.0' do
            expect(described_class.new( url: url ).time).to eq(0.0)
        end
    end

    describe '#body=' do
        it 'sets the #body' do
            body = 'Stuff...'
            r = described_class.new( url: url )
            r.body = body
            expect(r.body).to eq(body)
        end

        it 'forces it to a string' do
            r = described_class.new( url: url )
            r.body = nil
            expect(r.body).to eq('')
        end

        context 'when content-length is' do
            let(:body) { "abc\u3042\x81" }

            context 'text-based' do
                it 'removes invalid characters' do
                    r = described_class.new(
                        url:     'http://test.com',
                        headers: { 'Content-Type' => 'text/stuff' },
                        body:    'stuff'
                    )
                    r.body = body
                    expect(r.body).to eq("abcあ�")
                end
            end

            context 'not text-based' do
                it 'preserves invalid characters' do
                    r = described_class.new(
                        url:     'http://test.com',
                        headers: { 'Content-Type' => 'binary/stuff' },
                        body:    'stuff'
                    )
                    r.body = body
                    expect(r.body).to eq(body)
                end
            end

            context 'not available' do
                it 'removes invalid characters' do
                    r = described_class.new( url:  'http://test.com' )
                    r.body = body
                    expect(r.body).to eq("abcあ�")
                end
            end
        end
    end

    describe '#==' do
        context 'when responses are identical' do
            it 'returns true' do
                h = {
                    url:     'http://test.com',
                    headers: { 'Content-Type' => 'application/stuff' },
                    body:    'stuff'
                }
                expect(described_class.new( h.dup )).to eq(described_class.new( h.dup ))
            end
        end
        context 'when responses are not identical' do
            it 'returns false' do
                expect(described_class.new(
                    url:     'http://test.com',
                    headers: { 'Content-Type' => 'application/stuff' },
                    body:    'stuff'
                )).not_to eq(
                    described_class.new(
                        url:     'http://test.com',
                        headers: { 'Content-Type' => 'application/stuff1' },
                        body:    'stuff'
                    )
                )
            end
        end
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            h = {
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

            expect(described_class.new( h ).to_h).to eq(h)
        end
    end

end
