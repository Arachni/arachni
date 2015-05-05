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
        subject.should == Arachni::RPC::Serializer.deep_clone( subject )
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        %w(url code ip_address headers body time app_time total_time return_code
            return_message).each do |attribute|
            it "includes '#{attribute}'" do
                data[attribute].should == subject.send( attribute )
            end
        end

        it "includes 'request'" do
            data['request'].should == subject.request.to_rpc_data
        end

        it "does not include 'scope" do
            data.should_not include 'scope'
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(url code ip_address headers body time app_time total_time return_code
            return_message request).each do |attribute|
            it "restores '#{attribute}'" do
                restored.send( attribute ).should == subject.send( attribute )
            end
        end
    end

    describe '#status_line' do
        it 'returns the first line of the response' do
            @http.get( @url, mode: :sync ).status_line.should == 'HTTP/1.1 200 OK'
        end
    end

    describe '#modified?' do
        context 'when the #code is' do
            describe 200 do
                it 'returns false' do
                    described_class.new( url: @url, code: 200 ).should be_modified
                end
            end

            describe 304 do
                it 'returns true' do
                    described_class.new( url: @url, code: 304 ).should_not be_modified
                end
            end
        end
    end

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
                described_class.new( url: 'http://test.com', code: 200 ).redirection?.should be_false
            end
        end
    end

    describe '#to_s' do
        it 'returns the HTTP response as a string' do
            subject.to_s.should == "#{subject.headers_string}#{subject.body}"
        end
    end

    describe '#platforms' do
        it 'returns the platform manager for the resource' do
            Factory[:response].platforms.should be_kind_of Arachni::Platform::Manager
        end
    end

    describe '#app_time' do
        it 'returns the approximated webap pprocessing time' do
            response = @http.get( @url, mode: :sync )
            response.app_time.should > 0
            response.app_time.should < 0.01

            response = @http.get( "#{@url}/sleep", mode: :sync )
            response.app_time.should > 5
            response.app_time.should < 5.01
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
                    described_class.new( h ).text?.should be_true
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
                            described_class.new( h ).text?.should be_false
                        end
                    end

                    context 'text' do
                        it 'returns true' do
                            h = {
                                url:     'http://test.com',
                                headers: { 'Content-Type' => 'application/stuff' },
                                body:    'stuff'
                            }
                            described_class.new( h ).text?.should be_true
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
                    described_class.new( h ).text?.should be_false
                end
            end

            context nil do
                context 'and the response body is' do
                    context 'binary' do
                        it 'returns false' do
                            h = {
                                url:  'http://test.com',
                                body: "\00\00\00"
                            }
                            described_class.new( h ).text?.should == false
                        end
                    end

                    context 'text' do
                        it 'returns true' do
                            h = {
                                url:  'http://test.com',
                                body: 'stuff'
                            }
                            described_class.new( h ).text?.should be_true
                        end
                    end

                    context 'inconclusive' do
                        it 'returns nil' do
                            r = described_class.new(
                                url:  'http://test.com',
                                body: "abc\u3042\x81"
                            )
                            r.text?.should be_nil
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
            page.cookie_jar.should == parser.cookie_jar
            page.text?.should == parser.text?
        end
    end

    describe '#time=' do
        it 'sets the #time' do
            r = described_class.new( url: url )
            r.time = 1.2
            r.time.should == 1.2
        end

        it 'casts to Float' do
            r = described_class.new( url: url )
            r.time = '1.2'
            r.time.should == 1.2
        end
    end

    describe '#time' do
        it 'defaults to 0.0' do
            described_class.new( url: url ).time.should == 0.0
        end
    end

    describe '#body=' do
        it 'sets the #body' do
            body = 'Stuff...'
            r = described_class.new( url: url )
            r.body = body
            r.body.should == body
        end

        it 'freezes it' do
            r = described_class.new( url: url )
            r.body = 'Stuff...'
            r.body.should be_frozen
        end

        it 'forces it to a string' do
            r = described_class.new( url: url )
            r.body = nil
            r.body.should == ''
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
                    r.body.should == "abcあ�"
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
                    r.body.should == body
                end
            end

            context 'not available' do
                it 'removes invalid characters' do
                    r = described_class.new( url:  'http://test.com' )
                    r.body = body
                    r.body.should == "abcあ�"
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
                described_class.new( h.dup ).should == described_class.new( h.dup )
            end
        end
        context 'when responses are not identical' do
            it 'returns false' do
                described_class.new(
                    url:     'http://test.com',
                    headers: { 'Content-Type' => 'application/stuff' },
                    body:    'stuff'
                ).should_not ==
                    described_class.new(
                        url:     'http://test.com',
                        headers: { 'Content-Type' => 'application/stuff1' },
                        body:    'stuff'
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

            described_class.new( h ).to_h.should == h
        end
    end

end
