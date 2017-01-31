require 'spec_helper'

describe Arachni::HTTP::ProxyServer do

    before :all do
        @url = web_server_url_for( :proxy_server ) + '/'
    end

    let(:address) { Socket.ip_address_list.find(&:ipv4?).ip_address }
    let(:port) { Arachni::Utilities.available_port }

    def via_proxy( proxy, url )
        Typhoeus::Request.get(
            url,
            proxy: proxy.url,
            ssl_verifypeer:  false,
            ssl_verifyhost:  0
        )
    end

    def post_via_proxy( proxy, url )
        Typhoeus::Request.post(
            url,
            body: {
                '1' => '2',
                '3' => '4'
            },
            proxy: proxy.url,
            ssl_verifypeer:  false,
            ssl_verifyhost:  0
        )
    end

    def test_proxy( proxy )
        expect(via_proxy( proxy, @url ).body).to eq('GET')
    end

    it 'supports SSL interception' do
        url = web_server_url_for( :proxy_server_https )

        proxy = described_class.new
        proxy.start_async

        response = via_proxy( proxy, url )
        expect(response.code).to eq 200
        expect(response.body).to eq 'HTTPS GET'
    end

    it 'supports WebSockets'

    it 'removes any size limits on the HTTP responses' do
        Arachni::Options.http.response_max_size = 1

        proxy = described_class.new
        proxy.start_async
        test_proxy( proxy )
    end

    context 'when the response is text-based' do
        let(:url) { "#{@url}/text" }

        it 'sets charset encoding to UTF8' do
            proxy = described_class.new
            proxy.start_async

            expect(via_proxy( proxy, url ).headers['Content-Type']).to eq 'text/html; charset=utf-8'
        end

        it 'transcodes to UTF-8' do
            proxy = described_class.new
            proxy.start_async

            expect(via_proxy( proxy, url ).body.encoding.name).to eq 'UTF-8'
        end
    end

    context 'when the response is binary' do
        let(:url) { "#{@url}/binary" }

        it 'does not add a charset' do
            proxy = described_class.new
            proxy.start_async

            expect(via_proxy( proxy, url ).headers['Content-Type']).to eq 'application/binary'
        end
    end

    describe '#initialize' do
        describe ':address' do
            it 'sets the bind address' do
                proxy = described_class.new( address: address )
                proxy.start_async

                expect(URI(proxy.url).host).to eq(address)
                test_proxy proxy
            end
        end

        describe ':port' do
            it 'sets the listen port' do
                port = Arachni::Utilities.available_port

                proxy = described_class.new( port: port )
                proxy.start_async

                expect(URI(proxy.url).port).to eq(port)
                test_proxy proxy
            end
        end

        describe ':timeout' do
            it 'sets the HTTP request timeout' do
                proxy = described_class.new( timeout: 1 )
                proxy.start_async

                sleep_url = @url + 'sleep'

                expect(Typhoeus::Request.get( sleep_url ).code).not_to eq(0)
                expect(via_proxy( proxy, sleep_url ).code).to eq(504)
            end
        end

        describe ':concurrency' do
            it 'sets the HTTP request concurrency' do
                sleep_url = @url + 'sleep'

                proxy = described_class.new( concurrency: 2 )
                proxy.start_async
                time = Time.now
                threads = []
                2.times do
                    threads << Thread.new { via_proxy( proxy, sleep_url ) }
                end
                threads.each(&:join)
                expect((Time.now - time).to_i).to eq(5)

                proxy = described_class.new( concurrency: 1 )
                proxy.start_async
                time = Time.now
                threads = []
                2.times do
                    threads << Thread.new { via_proxy( proxy, sleep_url ) }
                end
                threads.each(&:join)
                expect((Time.now - time).to_i).to eq(10)
            end
        end

        describe ':request_handler' do
            it 'sets a block to handle each HTTP request before the request is forwarded to the origin server' do
                called = false
                proxy = described_class.new(
                    request_handler: proc do |request, _|
                        expect(request).to be_kind_of Arachni::HTTP::Request
                        called = true
                    end
                )
                proxy.start_async
                test_proxy proxy

                expect(called).to be_truthy
            end

            it 'sets a block to handle each HTTP response before the request is forwarded to the origin server' do
                called = false
                proxy = described_class.new(
                    request_handler: proc do |_, response|
                        expect(response).to be_kind_of Arachni::HTTP::Response
                        called = true
                    end
                )
                proxy.start_async
                test_proxy proxy

                expect(called).to be_truthy
            end

            it 'assigns the request to the response' do
                called = false
                proxy = described_class.new(
                    request_handler: proc do |_, response|
                        expect(response.request).to be_kind_of Arachni::HTTP::Request
                        called = true
                    end
                )
                proxy.start_async
                test_proxy proxy

                expect(called).to be_truthy
            end

            it 'fills in raw request data' do
                request = nil

                proxy = described_class.new(
                    request_handler: proc do |r, _|
                        request = r
                    end
                )
                proxy.start_async
                post_via_proxy( proxy, @url )

                expect(request.headers_string.split( "\r\n" ).sort).to eq(
                    ("POST / HTTP/1.1\r\n" <<
                    "Host: #{request.parsed_url.host}:#{request.parsed_url.port}\r\n" <<
                    "Accept-Encoding: gzip, deflate\r\n" <<
                    "User-Agent: Typhoeus - https://github.com/typhoeus/typhoeus\r\n" <<
                    "Accept: */*\r\n" <<
                    "Content-Length: 7\r\n" <<
                    "Accept-Language: en-US,en;q=0.8,he;q=0.6\r\n" <<
                    "Content-Type: application/x-www-form-urlencoded\r\n\r\n").split( "\r\n" ).sort
                )

                expect(request.effective_body).to eq('1=2&3=4')
            end

            context 'if the block returns false' do
                it 'does not perform the response and can manipulate the response' do
                    called = false
                    proxy = described_class.new(
                        request_handler: proc do |request, response|
                            expect(request).to be_kind_of Arachni::HTTP::Request
                            expect(response).to be_kind_of Arachni::HTTP::Response
                            called = true

                            response.code = 200
                            response.body = 'stuff'

                            false
                        end
                    )
                    proxy.start_async

                    response = via_proxy( proxy, @url )

                    expect(response.code).to eq 200
                    expect(response.body).to eq 'stuff'

                    expect(called).to be_truthy
                end
            end
        end

        describe ':response_handler' do
            it 'sets a block to handle each HTTP request once the origin server has responded' do
                called = false
                proxy = described_class.new(
                    response_handler: proc do |request, _|
                        expect(request).to be_kind_of Arachni::HTTP::Request
                        called = true
                    end
                )
                proxy.start_async

                test_proxy proxy

                expect(called).to be_truthy
            end

            it 'sets a block to handle each HTTP response once the origin server has responded' do
                called = false
                proxy = described_class.new(
                    response_handler: proc do |_, response|
                        expect(response).to be_kind_of Arachni::HTTP::Response
                        called = true
                    end
                )
                proxy.start_async

                test_proxy proxy

                expect(called).to be_truthy
            end

            it 'assigns the request to the response' do
                called = false
                proxy = described_class.new(
                    response_handler: proc do |_, response|
                        expect(response.request).to be_kind_of Arachni::HTTP::Request
                        called = true
                    end
                )
                proxy.start_async
                test_proxy proxy

                expect(called).to be_truthy
            end

            it 'can manipulate the response' do
                called = false
                proxy = described_class.new(
                    response_handler: proc do |request, response|
                        expect(request).to be_kind_of Arachni::HTTP::Request
                        expect(response).to be_kind_of Arachni::HTTP::Response
                        called = true

                        response.body = 'stuff'
                    end
                )
                proxy.start_async

                response = via_proxy( proxy, @url )

                expect(response.code).to eq(200)
                expect(response.body).to eq('stuff')

                expect(called).to be_truthy
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
                expect(proxy.running?).to be_falsey
            end
        end

        context 'when the server is running' do
            it 'returns true' do
                proxy = described_class.new
                proxy.start_async
                expect(proxy.running?).to be_truthy
            end
        end
    end

    describe '#address' do
        it 'returns the address of the proxy' do
            proxy = described_class.new( address: address, port: port )
            expect(proxy.url).to eq "http://#{address}:#{port}"
            proxy.start_async
            test_proxy proxy
        end
    end

    describe '#has_pending_requests?' do
        context 'when there are pending requests' do
            it 'returns true' do
                proxy = described_class.new
                proxy.start_async

                expect(proxy).to_not have_pending_requests
                Thread.new { via_proxy( proxy, @url + 'sleep' ) }
                sleep 1
                expect(proxy).to have_pending_requests
            end
        end

        context 'when there are no pending requests' do
            it 'returns false' do
                proxy = described_class.new
                proxy.start_async

                expect(proxy).to_not have_pending_requests
                via_proxy( proxy, @url + 'sleep' )
                expect(proxy).to_not have_pending_requests
            end
        end
    end

    describe '#pending_requests' do
        context 'when there are pending requests' do
            it 'returns the amount' do
                proxy = described_class.new
                proxy.start_async

                expect(proxy.pending_requests).to eq(0)
                3.times do
                    Thread.new { via_proxy( proxy, @url + 'sleep' ) }
                end
                sleep 1
                expect(proxy.pending_requests).to eq(3)
            end
        end

        context 'when there are no pending requests' do
            it 'returns 0' do
                proxy = described_class.new
                proxy.start_async

                expect(proxy.pending_requests).to eq(0)
                via_proxy( proxy, @url + 'sleep' )
                expect(proxy.pending_requests).to eq(0)
            end
        end
    end
end
