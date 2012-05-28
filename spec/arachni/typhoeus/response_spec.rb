require_relative '../../spec_helper'

describe Typhoeus::Response do

    describe '#location' do
        it 'should return the content-type' do
            Typhoeus::Response.new.location.should be_nil

            ct = 'http://test.com'
            h = { headers_hash: { 'location' => ct } }
            Typhoeus::Response.new( h ).location.should == ct

            h = { headers_hash: { 'Location' => ct } }
            Typhoeus::Response.new( h ).location.should == ct
        end
    end

    describe '#content_type' do
        it 'should return the content-type' do
            Typhoeus::Response.new.content_type.should be_nil

            ct = 'text/html'
            h = { headers_hash: { 'content-type' => ct } }
            Typhoeus::Response.new( h ).content_type.should == ct

            h = { headers_hash: { 'Content-Type' => ct } }
            Typhoeus::Response.new( h ).content_type.should == ct
        end
    end

    describe '#redirection?' do
        context 'when the response is a redirection' do
            it 'should return true' do
                300.upto( 399 ) do |c|
                    Typhoeus::Response.new( code: c ).redirection?.should be_true
                end
            end
        end

        context 'when the response is not a redirection' do
            it 'should return true' do
                Typhoeus::Response.new( code: 200 ).redirection?.should be_false
            end
        end
    end

    describe '#to_hash' do
        it 'should return a hash representation of self' do
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
