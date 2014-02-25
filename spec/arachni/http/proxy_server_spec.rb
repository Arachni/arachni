require 'spec_helper'

describe Arachni::HTTP::ProxyServer do

    before :all do
        @url = web_server_url_for( :proxy_server ) + '/'
    end

    def via_proxy( proxy, url )
        Typhoeus::Request.get(
            url,
            proxy: proxy.address,
            ssl_verifypeer:  false,
            ssl_verifyhost:  0
        )
    end

    def test_proxy( proxy )
        via_proxy( proxy, @url ).body.should == 'GET'
    end

    it 'supports SSL interception' do
        url = web_server_url_for( :proxy_server_https ).gsub( 'http', 'https' )

        proxy = described_class.new
        proxy.start_async

        via_proxy( proxy, url ).body.should == 'HTTPS GET'
    end

    describe '#initialize' do
        describe :address do
            it 'sets the bind address' do
                address = WEBrick::Utils::getservername

                proxy = described_class.new( address: address )
                proxy.start_async

                proxy.address.split( ':' ).first.should == address
                test_proxy proxy
            end
        end

        describe :port do
            it 'sets the listen port' do
                port = Arachni::Utilities.available_port

                proxy = described_class.new( port: port )
                proxy.start_async

                proxy.address.split( ':' ).last.should == port.to_s
                test_proxy proxy
            end
        end

        describe :timeout do
            it 'sets the HTTP request timeout' do
                proxy = described_class.new( timeout: 1_000 )
                proxy.start_async

                sleep_url = @url + 'sleep'

                Typhoeus::Request.get( sleep_url ).code.should_not == 0
                via_proxy( proxy, sleep_url ).code.should == 0
            end
        end

        describe :request_handler do
            it 'sets a block to handle each HTTP request before the request is forwarded to the origin server' do
                called = false
                proxy = described_class.new(
                    request_handler: proc do |request, _|
                        request.should be_kind_of Arachni::HTTP::Request
                        called = true
                    end
                )
                proxy.start_async
                test_proxy proxy

                called.should be_true
            end

            it 'sets a block to handle each HTTP response before the request is forwarded to the origin server' do
                called = false
                proxy = described_class.new(
                    request_handler: proc do |_, response|
                        response.should be_kind_of Arachni::HTTP::Response
                        called = true
                    end
                )
                proxy.start_async
                test_proxy proxy

                called.should be_true
            end

            it 'assigns the request to the response' do
                called = false
                proxy = described_class.new(
                    request_handler: proc do |_, response|
                        response.request.should be_kind_of Arachni::HTTP::Request
                        called = true
                    end
                )
                proxy.start_async
                test_proxy proxy

                called.should be_true
            end

            context 'if the block returns false' do
                it 'does not perform the response and can manipulate the response' do
                    called = false
                    proxy = described_class.new(
                        request_handler: proc do |request, response|
                            request.should be_kind_of Arachni::HTTP::Request
                            response.should be_kind_of Arachni::HTTP::Response
                            called = true

                            response.code = 200
                            response.body = 'stuff'

                            false
                        end
                    )
                    proxy.start_async

                    via_proxy( proxy, @url ).body.should == 'stuff'

                    called.should be_true
                end
            end
        end

        describe :response_handler do
            it 'sets a block to handle each HTTP request once the origin server has responded' do
                called = false
                proxy = described_class.new(
                    response_handler: proc do |request, _|
                        request.should be_kind_of Arachni::HTTP::Request
                        called = true
                    end
                )
                proxy.start_async

                test_proxy proxy

                called.should be_true
            end

            it 'sets a block to handle each HTTP response once the origin server has responded' do
                called = false
                proxy = described_class.new(
                    response_handler: proc do |_, response|
                        response.should be_kind_of Arachni::HTTP::Response
                        called = true
                    end
                )
                proxy.start_async

                test_proxy proxy

                called.should be_true
            end

            it 'assigns the request to the response' do
                called = false
                proxy = described_class.new(
                    response_handler: proc do |_, response|
                        response.request.should be_kind_of Arachni::HTTP::Request
                        called = true
                    end
                )
                proxy.start_async
                test_proxy proxy

                called.should be_true
            end

            it 'can manipulate the response' do
                called = false
                proxy = described_class.new(
                    response_handler: proc do |request, response|
                        request.should be_kind_of Arachni::HTTP::Request
                        response.should be_kind_of Arachni::HTTP::Response
                        called = true

                        response.body = 'stuff'
                    end
                )
                proxy.start_async

                response = via_proxy( proxy, @url )

                response.code.should == 200
                response.body.should == 'stuff'

                called.should be_true
            end
        end
    end

    describe '#start_async' do
        it 'starts the server and blocks until has booted' do
            proxy = described_class.new
            proxy.start_async
            test_proxy proxy
        end
    end

    describe '#running?' do
        context 'when the server is not running' do
            it 'returns false' do
                proxy = described_class.new
                proxy.running?.should be_false
            end
        end

        context 'when the server is running' do
            it 'returns true' do
                proxy = described_class.new
                proxy.start_async
                proxy.running?.should be_true
            end
        end
    end

    describe '#address' do
        it 'returns the address of the proxy' do
            address = 'localhost'
            port    = Arachni::Utilities.available_port

            proxy = described_class.new( address: address, port: port )
            proxy.address.should == "#{address}:#{port}"
            proxy.start_async
            test_proxy proxy
        end
    end

    describe '#has_connections?' do
        context 'when there are active connections' do
            it 'returns true' do
                proxy = described_class.new
                proxy.start_async

                proxy.has_connections?.should be_false
                Thread.new { via_proxy( proxy, @url + 'sleep' ) }
                sleep 1
                proxy.has_connections?.should be_true
            end
        end

        context 'when there are no active connections' do
            it 'returns false' do
                proxy = described_class.new
                proxy.start_async

                proxy.has_connections?.should be_false
                via_proxy( proxy, @url + 'sleep' )
                proxy.has_connections?.should be_false
            end
        end
    end

    describe '#active_connections' do
        context 'when there are active connections' do
            it 'returns the amount' do
                proxy = described_class.new
                proxy.start_async

                proxy.active_connections.should == 0
                3.times do
                    Thread.new { via_proxy( proxy, @url + 'sleep' ) }
                end
                sleep 1
                proxy.active_connections.should == 3
            end
        end

        context 'when there are no active connections' do
            it 'returns 0' do
                proxy = described_class.new
                proxy.start_async

                proxy.active_connections.should == 0
                via_proxy( proxy, @url + 'sleep' )
                proxy.active_connections.should == 0
            end
        end
    end
end
