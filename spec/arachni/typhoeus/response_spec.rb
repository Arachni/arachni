require 'spec_helper'

describe Typhoeus::Response do

    before( :all ) do
        @http = Arachni::HTTP
        @url  = web_server_url_for( :http )
    end

    describe '#app_time' do
        it 'returns the approximated webap pprocessing time' do
            response = @http.get( @url, async: false ).response
            response.app_time.should > 0
            response.app_time.should < 0.01

            response = @http.get( "#{@url}/sleep", async: false ).response
            response.app_time.should > 5
            response.app_time.should < 5.01
        end
    end

    describe '#url' do
        it 'aliased to #effective_url' do
            url = 'http://stuff'
            res = Typhoeus::Response.new( effective_url: url )

            res.url.should == url
            res.url.should == res.effective_url
        end
    end

    describe '#location' do
        it 'returns the content-type' do
            Typhoeus::Response.new.location.should be_nil

            ct = 'http://test.com'
            h = { headers_hash: { 'location' => ct } }
            Typhoeus::Response.new( h ).location.should == ct

            h = { headers_hash: { 'Location' => ct } }
            Typhoeus::Response.new( h ).location.should == ct
        end
    end

    describe '#content_type' do
        it 'returns the content-type' do
            Typhoeus::Response.new.content_type.should be_nil

            ct = 'text/html'
            h = { headers_hash: { 'content-type' => ct } }
            Typhoeus::Response.new( h ).content_type.should == ct

            h = { headers_hash: { 'Content-Type' => ct } }
            Typhoeus::Response.new( h ).content_type.should == ct
        end
    end

    describe '#text?' do
        context 'when the content-type is' do
            context 'text/*' do
                it 'returns true' do
                    h = {
                        headers_hash: { 'Content-Type' => 'text/stuff' },
                        body:         "stuff"
                    }
                    Typhoeus::Response.new( h ).text?.should be_true
                end
            end

            context 'application/*' do
                context 'and the response body is' do
                    context 'binary' do
                        it 'returns false' do
                            h = {
                                headers_hash: { 'Content-Type' => 'application/stuff' },
                                body:         "\00\00\00"
                            }
                            Typhoeus::Response.new( h ).text?.should be_false
                        end
                    end

                    context 'text' do
                        it 'returns true' do
                            h = {
                                headers_hash: { 'Content-Type' => 'application/stuff' },
                                body:         "stuff"
                            }
                            Typhoeus::Response.new( h ).text?.should be_true
                        end
                    end
                end
            end

            context 'other' do
                it 'returns false' do
                    h = {
                        headers_hash: { 'Content-Type' => 'blah/stuff' },
                        body:         "stuff"
                    }
                    Typhoeus::Response.new( h ).text?.should be_false
                end
            end

            context nil do
                context 'and the response body is' do
                    context 'binary' do
                        it 'returns false' do
                            h = { body: "\00\00\00" }
                            Typhoeus::Response.new( h ).text?.should be_false
                        end
                    end

                    context 'text' do
                        it 'returns true' do
                            h = { body: "stuff" }
                            Typhoeus::Response.new( h ).text?.should be_true
                        end
                    end
                end
            end
        end
    end

    describe '#redirection?' do
        context 'when the response is a redirection' do
            it 'returns true' do
                300.upto( 399 ) do |c|
                    Typhoeus::Response.new( code: c ).redirection?.should be_true
                end
            end
        end

        context 'when the response is not a redirection' do
            it 'returns true' do
                Typhoeus::Response.new( code: 200 ).redirection?.should be_false
            end
        end
    end

    describe '#to_hash' do
        it 'returns a hash representation of self' do
            h = {
                "code" => 200,
                "curl_return_code" => nil,
                "curl_error_message" => nil,
                "status_message" => nil,
                "http_version" => nil,
                "headers" => nil,
                "body" => 'stuff',
                "time" => 0.1,
                "requested_url" => 'http://test.com',
                "requested_http_method" => :get,
                "start_time" => nil,
                "start_transfer_time" => nil,
                "app_connect_time" => nil,
                "pretransfer_time" => nil,
                "connect_time" => nil,
                "name_lookup_time" => nil,
                "effective_url" => nil,
                "primary_ip" => nil,
                "mock" => false,
                "headers_hash" => { 'Context-Type' => 'text/html' }
            }

            h2 = {}
            h.each { |k, v| h2[k.to_sym] = v }

            Typhoeus::Response.new( h2 ).to_hash.should == h
        end
    end
end
