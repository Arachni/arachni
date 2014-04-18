require 'spec_helper'

describe Arachni::HTTP::Request do
    it_should_behave_like 'Arachni::HTTP::Message'

    before( :all ) do
        @opts = Arachni::Options.instance
        @http = Arachni::HTTP::Client
        @url  = "#{web_server_url_for( :client )}/"
    end

    before( :each ){
        @opts.reset
        @opts.audit.links = true
        @opts.url  = @url
        @http.reset
    }

    let(:url){ @url }
    let(:url_with_query) { "#{url}/?id=1&stuff=blah" }
    let(:options) do
        {
            url:        url,
            method:     :get,
            parameters: { 'test' => 'blah' },
            body: {
                '1' => ' 2',
                ' 3' => '4'
            },
            headers_string: 'stuff',
            effective_body: '1=%202&%203=4',
            timeout:    10_000,
            headers:    { 'Content-Type' => 'test/html' },
            cookies:    { 'cname'=> 'cvalue' },
            username:   'user',
            password:   'pass'
        }
    end

    it "supports #{Arachni::RPC::Serializer}" do
        subject = described_class.new( options )
        subject.should == Arachni::RPC::Serializer.deep_clone( subject )
    end

    describe '#initialize' do
        it 'sets the instance attributes by the options' do
            r = described_class.new( options )
            r.url.should          == Arachni::Utilities.normalize_url( url )
            r.method.should       == options[:method]
            r.parameters.should   == options[:parameters]
            r.timeout.should      == options[:timeout]
            r.headers.should      == options[:headers]
            r.username.should     == options[:username]
            r.password.should     == options[:password]
        end

        it 'uses the setter methods when configuring' do
            options = { url: url, method: 'gEt', parameters: { test: 'blah' } }
            r = described_class.new( options )
            r.method.should == :get
            r.parameters.should == { 'test' => 'blah' }
        end

        context 'when url is not a String' do
            it 'raises ArgumentError' do
                raised = false
                begin
                    described_class.new
                rescue ArgumentError
                    raised = true
                end
                raised.should be_true
            end
        end
    end

    describe '#run' do
        it 'performs the request' do
            request  = described_class.new( url: @url )
            response = request.run

            response.should be_kind_of Arachni::HTTP::Response
            response.request.should == request
        end

        it 'calls #on_complete callbacks' do
            request  = described_class.new( url: @url )

            called = []
            request.on_complete do |r|
                called << r
            end

            response = request.run
            response.should be_kind_of Arachni::HTTP::Response
            response.request.should == request

            called.should == [response]
            called.first.request.should == request
        end

        it "fills in #{Arachni::HTTP::Request}#headers_string" do
            host = "#{Arachni::URI(@url).host}:#{Arachni::URI(@url).port}"
            described_class.new( url: @url ).run.request.headers_string.should ==
                "GET / HTTP/1.1\r\nHost: #{host}\r\nAccept-Encoding: gzip, " +
                    "deflate\r\nUser-Agent: Arachni/v1.0dev\r\nAccept: text/html," +
                    "application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n\r\n"
        end

        it "fills in #{Arachni::HTTP::Request}#effective_body" do
            described_class.new(
                url: @url,
                body: {
                    '1' => ' 2',
                    ' 3' => '4'
                },
                mode:   :sync,
                method: :post
            ).run.request.effective_body.should == "1=%202&%203=4"
        end
    end

    describe '#parameters' do
        it 'defaults to an empty Hash' do
            described_class.new( url: url ).parameters.should == {}
        end
    end

    describe '#parameters=' do
        it 'recursively forces converts keys and values to strings' do
            with_symbols = {
                test:         'blah',
                another_hash: {
                    stuff: 'test'
                }
            }
            with_strings = {
                'test'         => 'blah',
                'another_hash' => {
                    'stuff' => 'test'
                }
            }

            request = described_class.new( url: url )
            request.parameters = with_symbols
            request.parameters.should == with_strings
        end
    end

    describe '#on_complete' do
        context 'when passed a block' do
            it 'adds it as a callback to be passed the response' do
                request = described_class.new( url: url )

                passed_response = nil
                request.on_complete { |res| passed_response = res }

                response = Arachni::HTTP::Response.new( url: url )
                request.handle_response( response )

                passed_response.should == response
            end

            it 'can add multiple callbacks' do
                request = described_class.new( url: url )

                passed_responses = []

                2.times do
                    request.on_complete { |res| passed_responses << res }
                end

                response = Arachni::HTTP::Response.new( url: url )
                request.handle_response( response )

                passed_responses.size.should == 2
                passed_responses.uniq.size.should == 1
                passed_responses.uniq.first.should == response
            end
        end
    end

    describe '#clear_callbacks' do
        it 'clears #on_complete callbacks' do
            request = described_class.new( url: url )

            passed_response = nil
            request.on_complete { |res| passed_response = res }

            response = Arachni::HTTP::Response.new( url: url )
            request.clear_callbacks
            request.handle_response( response )

            passed_response.should be_nil
        end
    end


    describe '#handle_response' do
        it 'assigns self as the #request attribute of the response' do
            request = described_class.new( url: url )

            passed_response = nil
            request.on_complete { |res| passed_response = res }

            response = Arachni::HTTP::Response.new( url: url )
            request.handle_response( response )

            passed_response.request.should == request
        end

        it 'calls #on_complete callbacks' do
            response = Arachni::HTTP::Response.new( url: url, code: 200 )
            request = described_class.new( url: url )

            passed_response = nil
            request.on_complete { |res| passed_response = res }
            request.handle_response( response )

            passed_response.should == response
        end
    end

    describe '#parsed_url' do
        it 'returns the configured URL as a parsed object' do
            described_class.new( url: url ).parsed_url.should == Arachni::URI( url )
        end
    end

    describe '#method' do
        it 'defaults to :get' do
            described_class.new( url: url ).method.should == :get
        end
    end

    describe '#method=' do
        it 'normalizes the HTTP method to a downcase symbol' do
            request = described_class.new( url: url )
            request.method = 'pOsT'
            request.method.should == :post
        end
    end

    describe '#mode=' do
        it 'normalizes and sets the given mode' do
            request = described_class.new( url: url )
            request.mode = 'aSyNC'
            request.mode.should == :async
        end

        context 'when an invalid mode is given' do
            it 'raises ArgumentError' do
                request = described_class.new( url: url )
                expect { request.mode = 'stuff' }.to raise_error ArgumentError
            end
        end
    end

    describe '#effective_cookies' do
        it 'returns the given :cookies merged with the cookies in Headers' do
            request = described_class.new(
                url: url,
                headers: {
                    'Cookie' => 'my_cookie=my_value; cookie2=value2'
                },
                cookies: {
                    'cookie2' => 'updated_value',
                    'cookie3' => 'value3',
                }
            )

            request.cookies.should == {
                'cookie2' => 'updated_value',
                'cookie3' => 'value3'
            }
            request.effective_cookies.should == {
                'my_cookie' => 'my_value',
                'cookie2'   => 'updated_value',
                'cookie3'   => 'value3'
            }
        end
    end

    describe '#id' do
        it 'is incremented by the Arachni::HTTP::Client' do
            10.times do |i|
                @http.get( @url ).id.should == i
            end
        end
    end

    describe '#train' do
        it 'sets train? to return true' do
            req = described_class.new( url: url )
            req.train?.should be_false
            req.train
            req.train?.should be_true
        end
    end

    describe '#update_cookies' do
        it 'sets update_cookies? to return true' do
            req = described_class.new( url: url )
            req.update_cookies?.should be_false
            req.update_cookies
            req.update_cookies?.should be_true
        end
    end

    describe '#to_typhoeus' do
        it "converts #{described_class} to #{Typhoeus::Request}" do
            described_class.new( url: url ).to_typhoeus.should be_kind_of Typhoeus::Request
        end

        context 'when the request is blocking' do
            it 'forbids socket reuse' do
                described_class.new( url: url, mode: :sync ).to_typhoeus.
                    options[:forbid_reuse].should be_true
            end
        end

        context 'when the request is non-blocking' do
            it 'reuses sockets' do
                described_class.new( url: url, mode: :async ).to_typhoeus.
                    options[:forbid_reuse].should be_false
            end
        end
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            described_class.new( options ).to_h.should == options.tap do |h|
                h.delete :timeout
                h.delete :cookies
                h.delete :username
                h.delete :password
            end
        end
    end

end
