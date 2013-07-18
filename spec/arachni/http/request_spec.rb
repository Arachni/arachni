require 'spec_helper'

describe Arachni::HTTP::Request do
    it_should_behave_like 'Arachni::HTTP::Message'

    before( :all ) do
        @opts = Arachni::Options.instance
        @http = Arachni::HTTP::Client
        @url  = web_server_url_for( :client )
    end

    before( :each ){
        @opts.reset
        @opts.audit_links = true
        @opts.url  = @url
        @http.reset
    }

    let(:url){ @url }
    let(:url_with_query) { "#{url}/?id=1&stuff=blah" }

    describe '#initialize' do
        it 'sets the instance attributes by the options' do
            options = {
                method:     :get,
                parameters: { 'test' => 'blah' },
                timeout:    10_000,
                headers:    { 'Content-Type' => 'test/html' },
                cookies:    { 'cname'=> 'cvalue' }
            }
            r = described_class.new( url, options )
            r.url.should          == url
            r.method.should       == options[:method]
            r.parameters.should   == options[:parameters]
            r.timeout.should      == options[:timeout]
            r.headers.should      == options[:headers]
            r.cookies.should      == options[:cookies]
        end

        it 'uses the setter methods when configuring' do
            options = { method: 'gEt', parameters: { test: 'blah' } }
            r = described_class.new( url, options )
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

    describe '#parameters' do
        it 'defaults to an empty Hash' do
            described_class.new( url ).parameters.should == {}
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

            request = described_class.new( url )
            request.parameters = with_symbols
            request.parameters.should == with_strings
        end
    end

    describe '#on_complete' do
        context 'when passed a block' do
            it 'adds it as a callback to be passed the response' do
                request = described_class.new( url )

                passed_response = nil
                request.on_complete { |res| passed_response = res }

                response = Arachni::HTTP::Response.new( url )
                request.handle_response( response )

                passed_response.should == response
            end

            it 'can add multiple callbacks' do
                request = described_class.new( url )

                passed_responses = []

                2.times do
                    request.on_complete { |res| passed_responses << res }
                end

                response = Arachni::HTTP::Response.new( url )
                request.handle_response( response )

                passed_responses.size.should == 2
                passed_responses.uniq.size.should == 1
                passed_responses.uniq.first.should == response
            end
        end
    end

    describe '#handle_response' do
        it 'assigns self as the #request attribute of the response' do
            request = described_class.new( url )

            passed_response = nil
            request.on_complete { |res| passed_response = res }

            response = Arachni::HTTP::Response.new( url: url )
            request.handle_response( response )

            passed_response.request.should == request
        end

        it 'calls #on_complete callbacks' do
            response = Arachni::HTTP::Response.new( url: url, code: 200 )
            request = described_class.new( url )

            passed_response = nil
            request.on_complete { |res| passed_response = res }
            request.handle_response( response )

            passed_response.should == response
        end
    end

    describe '#parsed_url' do
        it 'returns the configured URL as a parsed object' do
            described_class.new( url ).parsed_url.should == Arachni::URI( url )
        end
    end

    describe '#method' do
        it 'defaults to :get' do
            described_class.new( url ).method.should == :get
        end
    end

    describe '#method=' do
        it 'normalizes the HTTP method to a downcase symbol' do
            request = described_class.new( url )
            request.method = 'pOsT'
            request.method.should == :post
        end
    end

    describe '#mode=' do
        it 'normalizes and sets the given mode' do
            request = described_class.new( url )
            request.mode = 'aSyNC'
            request.mode.should == :async
        end

        context 'when an invalid mode is given' do
            it 'raises ArgumentError' do
                request = described_class.new( url )
                expect { request.mode = 'stuff' }.to raise_error ArgumentError
            end
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
            req = described_class.new( '' )
            req.train?.should be_false
            req.train
            req.train?.should be_true
        end
    end

    describe '#update_cookies' do
        it 'sets update_cookies? to return true' do
            req = described_class.new( '' )
            req.update_cookies?.should be_false
            req.update_cookies
            req.update_cookies?.should be_true
        end
    end

end
