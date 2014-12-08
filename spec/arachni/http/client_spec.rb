# encoding: utf-8
require 'spec_helper'

describe Arachni::HTTP::Client do

    before( :all ) do
        @opts = Arachni::Options.instance
        @url  = web_server_url_for( :client )
    end
    before( :each ) do
        @opts.reset
        @opts.audit.links = true
        @opts.url = @url
        subject.reset
    end

    subject { Arachni::HTTP::Client }
    let(:custom_404_url) { @url + '/custom_404/' }

    it 'supports gzip content-encoding' do
        body = nil
        subject.get( @opts.url + 'gzip' ) { |res| body = res.body }
        subject.run
        body.should == 'success'
    end

    it 'preserves set-cookies' do
        body = nil
        subject.get( @opts.url + 'set_and_preserve_cookies', update_cookies: true )
        subject.run
        subject.cookies.first.value.should == "=stuf \00 here=="

        subject.get( @opts.url + 'cookies' ) { |res| body = res.body }
        subject.run
        YAML.load( body ).should == { 'stuff' => "=stuf \00 here==" }
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        [:request_count, :response_count, :time_out_count,
         :total_responses_per_second, :burst_response_time_sum,
         :burst_response_count, :burst_responses_per_second,
         :burst_average_response_time, :total_average_response_time,
         :max_concurrency].each do |k|
            it "includes #{k}" do
                statistics[k].should == subject.send(k)
            end
        end

    end

    describe Arachni::Options do
        describe '#url' do
            context 'when the target URL includes auth credentials' do
                it 'uses them globally' do
                    # first fail to make sure that our test server is actually working properly
                    code = 0
                    subject.get( "#{@opts.url}auth/simple-chars" ) { |res| code = res.code }
                    subject.run
                    code.should == 401

                    url = Arachni::Utilities.uri_parse( "#{@opts.url}auth/simple-chars" )
                    url.user = 'username'
                    url.password = 'password'
                    @opts.url = url.to_s

                    body = nil
                    subject.get( @opts.url ) { |res| body = res.body }
                    subject.run
                    body.should == 'authenticated!'
                end
            end
        end

        describe '#fingerprint?' do
            context true do
                it 'performs platform fingerprinting on the response' do
                    Arachni::Options.fingerprint

                    res = nil
                    subject.request( @url + '/fingerprint.php' ) { |c_res| res = c_res }
                    subject.run

                    res.platforms.to_a.should == [:php]
                end
            end

            context false do
                it 'does not fingerprint the response' do
                    Arachni::Platform::Manager.clear
                    Arachni::Options.do_not_fingerprint

                    res = nil
                    subject.request( @url + '/fingerprint.php' ) { |c_res| res = c_res }
                    subject.run

                    res.platforms.should be_empty
                end
            end
        end
    end

    describe Arachni::OptionGroups::HTTP do
        describe '#request_concurrency' do
            context Integer do
                it 'uses it as a max_concurrency' do
                    @opts.http.request_concurrency = 34
                    subject.reset
                    subject.max_concurrency.should == 34
                end
            end
            context 'nil' do
                it 'uses a default max concurrency setting' do
                    @opts.http.request_concurrency = nil
                    subject.reset
                    subject.max_concurrency.should == Arachni::HTTP::Client::MAX_CONCURRENCY
                end
            end
        end

        describe '#request_queue_size' do
            context 'when reached' do
                it 'performs an emergency run' do
                    Arachni::Options.http.request_queue_size = 10

                    responses = []
                    11.times do
                        subject.request do |response|
                            responses << response
                        end
                    end

                    responses.size.should == 10

                    subject.run
                    responses.size.should == 11
                end
            end
        end

        describe '#request_timeout' do
            context Integer do
                it 'uses it as an HTTP timeout' do
                    @opts.http.request_timeout = 10000000000
                    timed_out = false
                    subject.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                    subject.run
                    timed_out.should be_false

                    @opts.http.request_timeout = 1
                    subject.reset
                    timed_out = false
                    subject.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                    subject.run
                    timed_out.should be_true
                end
            end
            context 'nil' do
                it 'uses a default timeout setting' do
                    timed_out = false
                    subject.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                    subject.run
                    timed_out.should be_false
                end
            end
        end

        describe '#authentication_username and #authentication_password' do
            it 'uses them globally' do
                Arachni::Options.http.authentication_username = 'username1'
                Arachni::Options.http.authentication_password = 'password1'

                # first fail to make sure that our test server is actually working properly
                code = 0
                subject.get( @opts.url + 'auth/weird-chars' ) { |res| code = res.code }
                subject.run
                code.should == 401

                Arachni::Options.http.authentication_username,
                    Arachni::Options.http.authentication_password =
                        ['u se rname$@#@#%$3#@%@#', 'p a  :wo\'rd$@#@#%$3#@%@#' ]

                response = nil
                subject.get( @opts.url + 'auth/weird-chars' ) { |res| response = res }
                subject.run
                response.code.should == 200
                response.body.should == 'authenticated!'
            end
        end

        describe 'user_agent' do
            it 'uses the default user-agent setting' do
                body = nil
                subject.get( @opts.url + 'user-agent' ) { |res| body = res.body }
                subject.run

                body.should == @opts.http.user_agent
                @opts.http.user_agent.should == Arachni::OptionGroups::HTTP.defaults[:user_agent]
            end
            context String do
                it 'uses it as a user-agent' do
                    ua = 'my user agent'
                    @opts.http.user_agent = ua.dup
                    subject.reset

                    body = nil
                    subject.get( @opts.url + 'user-agent' ) { |res| body = res.body }
                    subject.run
                    body.should == ua
                end
            end
        end

        describe '#request_redirect_limit' do
            context Integer do
                it 'should not exceed that amount of redirects' do
                    @opts.http.request_redirect_limit = 2
                    code = nil
                    subject.get( @opts.url + 'redirect', follow_location: true ) { |res| code = res.code }
                    subject.run
                    code.should == 302

                    @opts.http.request_redirect_limit = 10
                    subject.reset

                    body = nil
                    subject.get( @opts.url + 'redirect', follow_location: true ) { |res| body = res.body }
                    subject.run
                    body.should == 'This is the end.'
                end
            end
            context 'nil' do
                it 'uses a default setting' do
                    subject.reset

                    body = nil
                    subject.get( @opts.url + 'redirect', follow_location: true ) { |res| body = res.body }
                    subject.run
                    body.should == 'This is the end.'
                end
            end
        end
    end

    describe '#sandbox' do
        it 'preserves state, runs the block and then restores state' do
            subject.cookies.should be_empty
            subject.get( @opts.url + 'set_and_preserve_cookies', update_cookies: true )
            subject.run
            subject.cookies.should be_any

            headers = subject.headers.dup

            signals = []
            subject.on_complete do |r|
                signals << :out
            end

            subject.get( @opts.url + 'out', mode: :sync )

            subject.sandbox do
                subject.cookies.should be_any
                subject.cookie_jar.clear
                subject.cookies.should be_empty

                subject.headers.should == headers
                subject.headers['X-Custom'] = 'stuff'
                subject.headers.include?( 'X-Custom' ).should be_true

                subject.on_complete do |r|
                    signals << :in
                end

                subject.get( @opts.url + 'in', mode: :sync )
            end

            subject.get( @opts.url + 'out', mode: :sync )

            signals.delete( :out )
            signals.size.should == 1

            subject.headers.include?( 'X-Custom' ).should be_false
            subject.cookies.should be_any
        end
    end

    describe '#url' do
        it 'returns the URL in opts' do
            subject.url.should == @opts.url.to_s
        end
    end

    describe '#headers' do
        it 'provides access to default headers' do
            headers = subject.headers
            headers['Accept'].should == 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
            headers['User-Agent'].should == 'Arachni/v' + Arachni::VERSION
        end

        context "when #{Arachni::OptionGroups::HTTP}#request_headers is set" do
            it 'includes them' do
                @opts.http.request_headers = {
                    'User-Agent' => 'My UA',
                    'From'       => 'Some dude',
                }
                subject.reset
                headers = subject.headers
                headers['From'].should == @opts.http.request_headers['From']
                headers['Accept'].should == 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
                headers['User-Agent'].should == @opts.http.request_headers['User-Agent']
            end
        end

        context 'when the authorized_by option is set' do
            it 'includes it in the From field' do
                @opts.authorized_by = 'The Dude'
                subject.reset
                subject.headers['From'].should == @opts.authorized_by
            end
        end
    end

    describe '#cookie_jar' do
        it 'provides access to the Cookie-jar' do
            subject.cookie_jar.is_a?( Arachni::HTTP::CookieJar ).should be_true
        end

        context "when #{Arachni::OptionGroups::HTTP}#cookie_jar_filepath is set" do
            it 'adds the contained cookies to the CookieJar' do
                @opts.http.cookie_jar_filepath = fixtures_path + 'cookies.txt'
                subject.cookie_jar.cookies.should be_empty
                subject.reset
                cookies = subject.cookie_jar.cookies
                cookies.size.should == 4
                cookies.should == Arachni::Utilities.cookies_from_file( '', @opts.http.cookie_jar_filepath )
            end
            context 'but the path is invalid' do
                it 'raises Arachni::HTTP::CookieJar::Error::CookieJarFileNotFound' do
                    @opts.http.cookie_jar_filepath = fixtures_path + 'cookies.does_not_exist.txt'
                    expect{ subject.reset }.to raise_error Arachni::HTTP::CookieJar::Error::CookieJarFileNotFound
                end
            end
        end

        context 'when the cookies option is set' do
            it 'adds those cookies to the CookieJar' do
                cookie_jar_file = fixtures_path + 'cookies.txt'
                @opts.http.cookies = Arachni::Utilities.cookies_from_file( '', cookie_jar_file )
                subject.cookie_jar.cookies.should be_empty
                subject.reset
                cookies = subject.cookie_jar.cookies
                cookies.size.should == 4
                cookies.should == @opts.http.cookies
            end
        end

        context "when #{Arachni::OptionGroups::HTTP}#cookie_string is set" do
            it 'parses the string and add those cookies to the CookieJar' do
                @opts.http.cookie_string = 'my_cookie_name=val1;blah_name=val2; stuff=%25blah; another_name=another_val'
                subject.cookie_jar.cookies.should be_empty
                subject.reset
                cookies = subject.cookie_jar.cookies
                cookies.size.should == 4
                cookies.first.name.should == 'my_cookie_name'
                cookies.first.value.should == 'val1'
                cookies[1].name.should == 'blah_name'
                cookies[1].value.should == 'val2'
                cookies[2].name.should == 'stuff'
                cookies[2].value.should == '%blah'
                cookies.last.name.should == 'another_name'
                cookies.last.value.should == 'another_val'
            end
        end
    end

    describe '#cookies' do
        it 'returns the current cookies' do
            @opts.http.cookie_string = 'my_cookie_name=val1;blah_name=val2; another_name=another_val'
            subject.cookie_jar.cookies.should be_empty
            subject.reset
            subject.cookies.size.should == 3
            subject.cookies.should == subject.cookie_jar.cookies
        end
    end

    describe '#after_run' do
        it 'sets blocks to be called after #run' do
            called = false
            subject.after_run { called = true }
            subject.run
            called.should be_true

            called = false
            subject.run
            called.should be_false
        end

        context 'when the callback creates new requests' do
            it 'run these too' do
                called = false
                subject.after_run do
                    subject.get do
                        called = true
                    end
                end
                subject.run
                called.should be_true

                called = false
                subject.run
                called.should be_false
            end
        end

        context 'when the callback creates new callbacks' do
            it 'run these too' do
                called = false
                subject.after_run do
                    subject.after_run { called = true }
                end
                subject.run
                called.should be_true
            end
        end
    end

    describe '#run' do
        it 'performs the queued requests' do
            response = nil
            subject.request { |r| response = r }

            subject.run

            response.should be_kind_of Arachni::HTTP::Response
        end

        it 'returns true' do
            subject.run.should be_true
        end

        it 'calls the after_each_run callbacks EVERY TIME' do
            called = false
            subject.after_each_run { called = true }
            subject.run
            called.should be_true
            called = false
            subject.run
            called.should be_true
        end

        it 'calculates the burst average response time' do
            subject.run
            subject.burst_runtime.should > 0
        end

        it 'updates burst_response_time_sum, burst_response_count,' +
               ' burst_average_response_time and burst_responses_per_second' +
               ' during runtime and resets them afterwards' do
            subject.total_runtime.to_i.should          == 0
            subject.total_average_response_time.should == 0
            subject.total_responses_per_second.should  == 0

            subject.burst_response_time_sum.should     == 0
            subject.burst_response_count.should        == 0
            subject.burst_average_response_time.should == 0
            subject.burst_responses_per_second.should  == 0

            total_runtime               = 0
            total_average_response_time = 0
            total_responses_per_second  = 0

            burst_response_time_sum     = 0
            burst_response_count        = 0
            burst_average_response_time = 0
            burst_responses_per_second  = 0

            20.times do
                subject.get do
                    total_runtime               = subject.total_runtime
                    total_average_response_time = subject.total_average_response_time
                    total_responses_per_second  = subject.total_responses_per_second

                    burst_response_time_sum     = subject.burst_response_time_sum
                    burst_response_count        = subject.burst_response_count
                    burst_average_response_time = subject.burst_average_response_time
                    burst_responses_per_second  = subject.burst_responses_per_second
                end
            end

            subject.run

            total_runtime.should               > 0
            total_average_response_time.should > 0
            total_responses_per_second.should  > 0

            burst_response_time_sum.should     > 0
            burst_response_count.should        > 0
            burst_average_response_time.should > 0
            burst_responses_per_second.should  > 0
        end

        context "when a #{RuntimeError} occurs" do
            it 'returns nil' do
                subject.instance.stub(:client_run){ raise }

                subject.run.should be_nil
            end
        end
    end

    describe '#abort' do
        it 'aborts the running requests on a best effort basis' do
            cnt = 0
            n = 50
            n.times do |i|
                subject.get do
                    cnt += 1
                    subject.abort
                end
            end
            subject.run
            cnt.should < n
        end
    end

    describe '#max_concurrency' do
        it 'defaults to 20' do
            subject.max_concurrency.should == 20
        end
        it 'respects the http_request_concurrency option' do
            @opts.http.request_concurrency = 50
            subject.reset
            subject.max_concurrency.should == 50
        end
    end

    describe '#max_concurrency=' do
        it 'sets the max_concurrency setting' do
            subject.max_concurrency.should_not == 30
            subject.max_concurrency = 30
            subject.max_concurrency.should == 30
        end
    end

    describe '#request' do
        it "uses the URL in #{Arachni::Options}#url as a default" do
            url = nil
            subject.request{ |res| url = res.url }
            subject.run
            url.start_with?( @opts.url.to_s ).should be_true
        end

        it 'raises exception when no URL is available' do
            @opts.reset
            subject.reset
            expect { subject.request }.to raise_error
        end

        it "fills in #{Arachni::HTTP::Request}#headers_string" do
            host = "#{Arachni::URI(@url).host}:#{Arachni::URI(@url).port}"
            subject.request( @url, mode: :sync ).request.headers_string.should ==
                "GET / HTTP/1.1\r\nHost: #{host}\r\nAccept-Encoding: gzip, " +
                    "deflate\r\nUser-Agent: Arachni/v#{Arachni::VERSION}\r\nAccept: text/html," +
                    "application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n\r\n"
        end

        it "fills in #{Arachni::HTTP::Request}#effective_body" do
            subject.request( @url,
               body: {
                   '1' => ' 2',
                   ' 3' => '4'
               },
               mode:   :sync,
               method: :post
            ).request.effective_body.should == "1=%202&%203=4"
        end

        describe :response_max_size do
            context "when #{Arachni::OptionGroups::HTTP}#response_max_size is specified" do
                it 'ignores bodies of responses which are larger than specified' do
                    @opts.http.response_max_size = 0
                    subject.request( @url + '/http_response_max_size',
                                   mode: :sync
                    ).body.should be_empty

                    @opts.http.response_max_size = 1
                    subject.request( @url + '/http_response_max_size',
                                   mode: :sync
                    ).body.should be_empty

                    @opts.http.response_max_size = 999999
                    subject.request( @url + '/http_response_max_size',
                                   mode: :sync
                    ).body.should be_empty

                    @opts.http.response_max_size = 1000000
                    subject.request( @url + '/http_response_max_size',
                                   mode: :sync
                    ).body.should_not be_empty
                end
            end

            context 'when specified' do
                it 'ignores bodies of responses which are larger than specified' do
                    subject.request( @url + '/http_response_max_size',
                                   mode: :sync,
                                   response_max_size: 0
                    ).body.should be_empty

                    subject.request( @url + '/http_response_max_size',
                                   mode: :sync,
                                   response_max_size: 1
                    ).body.should be_empty

                    subject.request( @url + '/http_response_max_size',
                                   mode: :sync,
                                   response_max_size: 999999
                    ).body.should be_empty

                    subject.request( @url + '/http_response_max_size',
                                   mode: :sync,
                                   response_max_size: 1000000
                    ).body.should_not be_empty
                end
            end

            context 'by default' do
                it 'does not enforce a limit' do
                    subject.request( @url + '/http_response_max_size',
                                   mode: :sync
                    ).body.should_not be_empty
                end
            end
        end

        describe :no_cookie_jar do
            context true do
                it 'skips the cookie-jar' do
                    body = nil
                    subject.request( @url + '/cookies', no_cookie_jar: true ) { |res| body = res.body }
                    subject.run
                    YAML.load( body ).should == {}
                end
            end
            context false do
                it 'uses the cookie_jar' do
                    @opts.http.cookie_string = 'my_cookie_name=val1;blah_name=val2;another_name=another_val'
                    subject.cookie_jar.cookies.should be_empty
                    subject.reset

                    body = nil

                    subject.request( @url + '/cookies', no_cookie_jar: false ) { |res| body = res.body }
                    subject.run
                    YAML.load( body ).should == {
                        'my_cookie_name' => 'val1',
                        'blah_name' => 'val2',
                        'another_name' => 'another_val'
                    }
                end
                context 'when custom cookies are provided' do
                    it 'merges them with the cookie_jar and override it' do
                        @opts.http.cookie_string = 'my_cookie_name=val1;blah_name=val2;another_name=another_val'
                        subject.cookie_jar.cookies.should be_empty
                        subject.reset

                        body = nil

                        custom_cookies = { 'newcookie' => 'newval', 'blah_name' => 'val3' }
                        subject.request( @url + '/cookies', cookies: custom_cookies,
                                       no_cookie_jar: false ) { |res| body = res.body }
                        subject.run
                        YAML.load( body ).should == {
                            'my_cookie_name' => 'val1',
                            'blah_name' => 'val3',
                            'another_name' => 'another_val',
                            'newcookie' => 'newval'
                        }
                    end
                end
            end
            context 'nil' do
                it 'defaults to false' do
                    @opts.http.cookie_string = 'my_cookie_name=val1;blah_name=val2;another_name=another_val'
                    subject.cookie_jar.cookies.should be_empty
                    subject.reset

                    body = nil

                    subject.request( @url + '/cookies' ) { |res| body = res.body }
                    subject.run
                    YAML.load( body ).should == {
                        'my_cookie_name' => 'val1',
                        'blah_name' => 'val2',
                        'another_name' => 'another_val'
                    }
                end
            end
        end

        describe :body do
            it 'uses its value as a request body' do
                req_body = 'heyaya'
                body = nil
                subject.request( @url + '/body', method: :post, body: req_body ) { |res| body = res.body }
                subject.run
                body.should == req_body
            end
        end

        describe :method do
            describe 'nil' do
                it 'performs a GET HTTP request' do
                    body = nil
                    subject.request( @url ) { |res| body = res.body }
                    subject.run
                    body.should == 'GET'
                end
            end
            describe :get do
                it 'performs a GET HTTP request' do
                    body = nil
                    subject.request( @url, method: :get ) { |res| body = res.body }
                    subject.run
                    body.should == 'GET'
                end

                context 'when there are both query string and hash params' do
                    it 'merges them while giving priority to the hash params' do
                        body = nil
                        params = {
                            'param1' => 'value1_updated',
                            'param2' => 'value 2'
                        }
                        url = @url + '/echo?param1=value1&param3=value3'
                        subject.request( url, parameters: params, method: :get ){ |res| body = res.body }
                        subject.run
                        YAML.load( body ).should eq params.merge( 'param3' => 'value3' )
                    end
                end
            end
            describe :post do
                it 'performs a POST HTTP request' do
                    body = nil
                    subject.request( @url, method: :post ) { |res| body = res.body }
                    subject.run
                    body.should == 'POST'
                end
            end
            describe :put do
                it 'performs a PUT HTTP request' do
                    body = nil
                    subject.request( @url, method: :put ) { |res| body = res.body }
                    subject.run
                    body.should == 'PUT'
                end
            end
            describe :options do
                it 'performs a OPTIONS HTTP request' do
                    body = nil
                    subject.request( @url, method: :options ) { |res| body = res.body }
                    subject.run
                    body.should == 'OPTIONS'
                end
            end
            describe :delete do
                it 'performs a POST HTTP request' do
                    body = nil
                    subject.request( @url, method: :delete ) { |res| body = res.body }
                    subject.run
                    body.should == 'DELETE'
                end
            end
        end

        describe :parameters do
            it 'specifies the query params as a hash' do
                body = nil
                params = { 'param' => 'value' }
                subject.request( @url + '/echo', parameters: params ) { |res| body = res.body }
                subject.run
                params.should eq YAML.load( body )
            end

            it 'preserves nullbytes' do
                body = nil
                params = { "pa\0ram" => "v\0alue" }
                subject.request( @url + '/echo', parameters: params ) { |res| body = res.body }
                subject.run
                params.should eq YAML.load( body )
            end
        end

        describe :body do
            it 'properly encodes special characters' do
                body = nil
                params = { '% param\ +=&;' => '% value\ +=&;', 'nil' => nil }
                subject.request( @url + '/echo', method: :post, body: params ) { |res| body = res.body }
                subject.run
                YAML.load( body ).should == { '% param\ +=&;' => '% value\ +=&;', 'nil' => '' }
            end

            it 'preserves nullbytes' do
                body = nil
                params = { "st\0uff" => "test\0" }
                subject.request( @url + '/echo', method: :post, body: params, ) { |res| body = res.body }
                subject.run
                YAML.load( body ).should == params
            end
        end

        describe :timeout do
            describe 'nil' do
                it 'runs without a timeout' do
                    timed_out = false
                    subject.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                    subject.run
                    timed_out.should be_false
                end
            end
            describe Numeric do
                it 'sets a timeout value in milliseconds' do
                    timed_out = false
                    subject.request( @url + '/sleep', timeout: 4_000 ) { |res| timed_out = res.timed_out? }
                    subject.run
                    timed_out.should be_true

                    timed_out = false
                    subject.request( @url + '/sleep', timeout: 6_000 ) { |res| timed_out = res.timed_out? }
                    subject.run
                    timed_out.should be_false
                end
            end
        end

        describe ':username/:password' do
            it 'uses them to authenticate' do
                # first fail to make sure that our test server is actually working properly
                code = 0
                subject.get( @opts.url + 'auth/weird-chars' ) { |res| code = res.code }
                subject.run
                code.should == 401

                response = nil
                subject.get(
                    @opts.url + 'auth/weird-chars',
                    username: 'u se rname$@#@#%$3#@%@#',
                    password: 'p a  :wo\'rd$@#@#%$3#@%@#' ) { |res| response = res }
                subject.run
                response.code.should == 200
                response.body.should == 'authenticated!'
            end
        end

        describe :cookies do
            it 'preserves nullbytess' do
                cookies = { "name\0" => "val\0" }
                body = nil
                subject.request( @url + '/cookies', cookies: cookies ) { |res| body = res.body }
                subject.run
                YAML.load( body ).should == cookies
            end

            describe 'nil' do
                it 'uses te cookies in the CookieJar' do
                    @opts.http.cookie_string = 'my_cookie_name=val1;blah_name=val2;another_name=another_val'
                    subject.cookie_jar.cookies.should be_empty
                    subject.reset

                    body = nil
                    subject.request( @url + '/cookies' ) { |res| body = res.body }
                    subject.run
                    YAML.load( body ).should == {
                        'my_cookie_name' => 'val1',
                        'blah_name' => 'val2',
                        'another_name' => 'another_val'
                    }
                end

                it 'only sends the appropriate cookies for the domain' do
                    cookies = []
                    cookies << Arachni::Element::Cookie.new(
                        url:    'http://test.com',
                        inputs: { 'key1' => 'val1' }
                    )
                    cookies << Arachni::Element::Cookie.new(
                        url:    @url,
                        inputs: { 'key2' => 'val2' }
                    )

                    subject.cookie_jar.update( cookies )
                    body = nil
                    subject.request( @url + '/cookies' ) { |res| body = res.body }
                    subject.run
                    YAML.load( body ).should == { 'key2' => 'val2' }
                end
            end

            describe Hash do
                it 'uses the key-value pairs as cookies' do
                    cookies = { 'name' => 'val' }
                    body = nil
                    subject.request( @url + '/cookies', cookies: cookies ) { |res| body = res.body }
                    subject.run
                    YAML.load( body ).should == cookies
                end

                it 'merges them with the cookie-jar' do
                    @opts.http.cookie_string = 'my_cookie_name=val1;blah_name=val2;another_name=another_val'
                    subject.cookie_jar.cookies.should be_empty
                    subject.reset

                    body = nil
                    subject.request(
                        @url + '/cookies',
                        cookies: {
                            'my_cookie_name' => 'updated_val'
                        }
                    ) { |res| body = res.body }
                    subject.run

                    YAML.load( body ).should == {
                        'my_cookie_name' => 'updated_val',
                        'blah_name' => 'val2',
                        'another_name' => 'another_val'
                    }
                end

                context 'when also given a Cookie header' do
                    it 'merges them, giving priority to the Hash' do
                        cookies = { 'name' => 'val' }
                        options = {
                            cookies: cookies,
                            headers: {
                                'Cookie' => 'test=1;name=2'
                            }
                        }

                        body = nil
                        subject.request( @url + '/cookies', options ) { |res| body = res.body }
                        subject.run

                        YAML.load( body ).should == { 'test' => '1', 'name' => 'val' }
                    end
                end
            end
        end

        describe :mode do
            describe 'nil' do
                it 'performs the request asynchronously' do
                    performed = false
                    subject.request( @url ) { performed = true }
                    subject.run
                    performed.should be_true
                end
            end
            describe :async do
                it 'performs the request asynchronously' do
                    performed = false
                    subject.request( @url, mode: :sync ) { performed = true }
                    subject.run
                    performed.should be_true
                end
            end
            describe :sync do
                it 'performs the request synchronously and returns the response' do
                    subject.request( @url, mode: :sync ).should be_kind_of Arachni::HTTP::Response
                end

                it 'assigns a #request to the returned response' do
                    subject.request( @url, mode: :sync ).request.should be_kind_of Arachni::HTTP::Request
                end

                context 'when a block is given' do
                    it 'passes the response to it as well' do
                        called = []
                        response = subject.request( @url, mode: :sync ) do |r|
                            called << r
                        end

                        response.should be_kind_of Arachni::HTTP::Response
                        called.should == [response]
                    end
                end
            end
        end

        describe :headers do
            describe 'nil' do
                it 'uses the default headers' do
                    body = nil
                    subject.request( @url + '/headers' ) { |res| body = res.body }
                    subject.run
                    sent_headers = YAML.load( body )
                    subject.headers.each { |k, v| sent_headers[k].should == v }
                end
            end

            describe Hash do
                it 'merges them with the default headers' do
                    headers = { 'My-Header' => 'my value'}
                    body = nil
                    subject.request( @url + '/headers', headers: headers ) { |res| body = res.body }
                    subject.run
                    sent_headers = YAML.load( body )
                    subject.headers.merge( headers ).each { |k, v| sent_headers[k].should == v }
                end
            end
        end

        describe :update_cookies do
            describe 'nil' do
                it 'skips the cookie_jar' do
                    cookies = []
                    cookies << Arachni::Element::Cookie.new(
                        url: @url,
                        inputs: { 'key2' => 'val2' }
                    )
                    subject.update_cookies( cookies )
                    subject.request( @url + '/update_cookies' )
                    subject.run
                    subject.cookies.should == cookies
                end
            end

            describe false do
                it 'skips the cookie_jar' do
                    cookies = []
                    cookies << Arachni::Element::Cookie.new(
                        url: @url,
                        inputs: { 'key2' => 'val2' }
                    )
                    subject.update_cookies( cookies )
                    subject.request( @url + '/update_cookies', update_cookies: false )
                    subject.run
                    subject.cookies.should == cookies
                end
            end

            describe true do
                it 'updates the cookie_jar' do
                    cookies = []
                    cookies << Arachni::Element::Cookie.new(
                        url:    @url,
                        name:   'key2',
                        value:  'val2',
                        domain: Arachni::URI( @url ).domain
                    )
                    subject.update_cookies( cookies )
                    subject.request( @url + '/update_cookies', update_cookies: true )
                    subject.run
                    subject.cookies.first.value.should == cookies.first.value + ' [UPDATED!]'
                end
            end
        end

        describe :follow_location do
            describe 'nil' do
                it 'ignores redirects' do
                    res = nil
                    subject.request( @url + '/follow_location' ) { |c_res| res = c_res }
                    subject.run
                    res.url.start_with?( @url + '/follow_location' ).should be_true
                    res.body.should == ''
                end
            end
            describe false do
                it 'ignores redirects' do
                    res = nil
                    subject.request( @url + '/follow_location', follow_location: false ) { |c_res| res = c_res }
                    subject.run
                    res.url.start_with?( @url + '/follow_location' ).should be_true
                    res.body.should == ''
                end
            end
            describe true do
                it 'follows redirects' do
                    res = nil
                    subject.request( @url + '/follow_location', follow_location: true ) { |c_res| res = c_res }
                    subject.run
                    res.url.should == @url + '/redir_2'
                    res.body.should == "Welcome to redir_2!"
                end
            end
        end

        context 'when cookie-jar lookup fails' do
            it 'only uses the given cookies' do
                @opts.http.cookie_string = 'my_cookie_name=val1;blah_name=val2;another_name=another_val'
                subject.cookie_jar.cookies.should be_empty
                subject.reset
                subject.cookie_jar.cookies.should be_any

                subject.cookie_jar.stub(:for_url) { raise }

                body = nil
                subject.request(
                    @url + '/cookies',
                    cookies: { 'blah' => 'val' }
                ) { |res| body = res.body }
                subject.run

                YAML.load( body ).should == { 'blah' => 'val' }
            end
        end
    end

    describe '#get' do
        it 'queues a GET request' do
            body = nil
            subject.get { |res| body = res.body }
            subject.run
            body.should == 'GET'
        end
    end

    describe '#trace' do
        it 'queues a TRACE request' do
            subject.trace.method.should == :trace
        end
    end

    describe '#post' do
        it 'queues a POST request' do
            body = nil
            subject.post { |res| body = res.body }
            subject.run
            body.should == 'POST'
        end

        it 'passes :parameters as a #request :body' do
            body = nil
            params = { '% param\ +=&;' => '% value\ +=&;', 'nil' => nil }
            subject.post( @url + '/echo', parameters: params ) { |res| body = res.body }
            subject.run
            YAML.load( body ).should == { '% param\ +=&;' => '% value\ +=&;', 'nil' => '' }
        end
    end

    describe '#cookie' do
        it 'queues a GET request' do
            body = nil
            cookies = { 'name' => "v%+;al\00=" }
            subject.cookie( @url + '/cookies', parameters: cookies ) { |res| body = res.body }
            subject.run
            YAML.load( body ).should == cookies
        end
    end

    describe '#headers' do
        it 'queues a GET request' do
            body = nil
            headers = { 'name' => 'val' }
            subject.header( @url + '/headers', parameters: headers ) { |res| body = res.body }
            subject.run
            YAML.load( body )['Name'].should == headers.values.first
        end
    end

    describe '#queue' do
        it 'queues a request' do
            r = nil

            request = Arachni::HTTP::Request.new( url: @url )
            request.on_complete do |response|
                r = response
            end

            subject.queue request
            subject.run

            r.should be_kind_of Arachni::HTTP::Response
        end
    end

    describe '#update_cookies' do
        it 'updates the cookies' do
            cookies = []
            cookies << Arachni::Element::Cookie.new(
                url: @url,
                inputs: { 'key2' => 'val2' }
            )

            subject.cookies.should be_empty
            subject.update_cookies( cookies )
            subject.cookies.should == cookies
        end
    end

    describe '#on_new_cookies' do
        it 'adds blocks to be called when new cookies arrive' do
            cookies = []
            cookies << Arachni::Element::Cookie.new(
                url:    @url,
                inputs: { 'name' => 'value' }
            )
            res = Arachni::HTTP::Response.new( url: @url, headers: { 'Set-Cookie' => 'name=value' } )

            callback_cookies  = nil
            callback_response = nil
            subject.on_new_cookies do |cookies, res|
                callback_cookies  = cookies
                callback_response = res
            end
            subject.parse_and_set_cookies( res )

            callback_cookies.should == cookies
            callback_response.should == res
        end
    end

    describe '#parse_and_set_cookies' do
        it 'updates the cookies from a response and call on_new_cookies blocks' do
            cookies = []
            cookies << Arachni::Element::Cookie.new(
                url:    @url,
                inputs: { 'name' => 'value' }
            )
            res = Arachni::HTTP::Response.new( url: @url, headers: { 'Set-Cookie' => 'name=value' } )

            @opts.http.cookies.should be_empty
            subject.cookies.should be_empty
            subject.parse_and_set_cookies( res )
            subject.cookies.should == cookies
        end
    end

    describe '#custom_404?' do
        before { @custom_404 = @url + '/custom_404/' }

        context 'when not dealing with a custom 404 handler' do
            it 'returns false' do
                res = nil
                subject.get( @custom_404 + 'not' ) { |c_res| res = c_res }
                subject.run
                bool = false
                subject.custom_404?( res ) { |c_bool| bool = c_bool }
                subject.run
                bool.should be_false
            end
        end

        context 'when dealing with a static handler' do
            it 'returns true' do
                res = nil
                subject.get( @custom_404 + 'static/crap' ) { |c_res| res = c_res }
                subject.run
                bool = false
                subject.custom_404?( res ) { |c_bool| bool = c_bool }
                subject.run
                bool.should be_true
            end
        end

        context 'when dealing with a dynamic handler' do
            context 'which includes the requested resource in the response' do
                it 'returns true' do
                    res = nil
                    subject.get( @custom_404 + 'dynamic/crap' ) { |c_res| res = c_res }
                    subject.run
                    bool = false
                    subject.custom_404?( res ) { |c_bool| bool = c_bool }
                    subject.run
                    bool.should be_true
                end
            end
            context 'which includes constantly changing text in the response' do
                it 'returns true' do
                    res = nil
                    subject.get( @custom_404 + 'random/crap' ) { |c_res| res = c_res }
                    subject.run
                    bool = false
                    subject.custom_404?( res ) { |c_bool| bool = c_bool }
                    subject.run
                    bool.should be_true
                end
            end
            context 'which returns a combination of the above' do
                it 'returns true' do
                    res = nil
                    subject.get( @custom_404 + 'combo/crap' ) { |c_res| res = c_res }
                    subject.run
                    bool = false
                    subject.custom_404?( res ) { |c_bool| bool = c_bool }
                    subject.run
                    bool.should be_true
                end
            end
        end

        context 'when checking for an already checked URL' do
            it 'returns the cached result' do
                res = nil
                subject.get( @custom_404 + 'static/crap' ) { |c_res| res = c_res }
                subject.run

                bool = false
                subject.custom_404?( res ) { |c_bool| bool = c_bool }
                subject.run
                bool.should be_true

                fingerprints = 0
                subject.on_complete do
                    fingerprints += 1
                end

                res = nil
                subject.get( @custom_404 + 'static/crap' ) { |c_res| res = c_res }
                subject.run
                fingerprints.should > 0

                overhead = 0
                subject.on_complete do
                    overhead += 1
                end

                bool = false
                subject.custom_404?( res ) { |c_bool| bool = c_bool }
                subject.run
                bool.should be_true

                overhead.should == 0
            end
        end

        context "when the 404 cache exceeds #{described_class::CUSTOM_404_CACHE_SIZE} entries" do
            it 'it is pruned as soon as possible' do
                subject._404_cache.should be_empty

                (2 * described_class::CUSTOM_404_CACHE_SIZE).times do |i|
                    subject.get( @custom_404 + "static/#{i}/test" ) do |response|
                        subject.custom_404?( response ) {}
                    end
                end
                subject.run

                subject._404_cache.size.should == described_class::CUSTOM_404_CACHE_SIZE
            end
        end
    end

    describe '#checked_but_not_custom_404?' do
        let(:url) { custom_404_url + 'combo/crap' }
        let(:path) { subject.get_path( url ) }

        context 'when the page has been fingerprinted for a custom 404 handler' do
            context 'and it has a custom handler' do
                it 'returns false' do
                    subject.get( url ) do |response|
                        subject.custom_404?( response ) {}
                    end
                    subject.run

                    subject.checked_but_not_custom_404?( path ).should be_false
                end
            end

            context 'and it does not have a custom handler' do
                it 'returns true' do
                    subject.get( @url ) do |response|
                        subject.custom_404?( response ) {}
                    end
                    subject.run

                    subject.checked_but_not_custom_404?( subject.get_path( @url ) ).should be_true
                end
            end
        end

        context 'when the page has not been fingerprinted for a custom 404 handler' do
            it 'returns false' do
                subject.checked_but_not_custom_404?( path ).should be_false
            end
        end
    end

    describe '#checked_for_custom_404?' do
        let(:url) { custom_404_url + 'combo/crap' }

        context 'when the page has been fingerprinted for a custom 404 handler' do
            context 'and it has a custom handler' do
                it 'returns true' do
                    subject.get( url ) do |response|
                        subject.custom_404?( response ) {}
                    end
                    subject.run

                    subject.checked_for_custom_404?( url ).should be_true
                end
            end

            context 'and it does not have a custom handler' do
                it 'returns true' do
                    subject.get( @url ) do |response|
                        subject.custom_404?( response ) {}
                    end
                    subject.run

                    subject.checked_for_custom_404?( @url ).should be_true
                end
            end
        end

        context 'when the page has not been fingerprinted for a custom 404 handler' do
            it 'returns false' do
                subject.checked_for_custom_404?( url ).should be_false
            end
        end
    end

    describe 'needs_custom_404_check?' do
        context 'when #checked_for_custom_404?' do
            context false do
                before(:each) { subject.instance.stub(:checked_for_custom_404?) { false } }

                it 'returns true' do
                    subject.needs_custom_404_check?( @url ).should be_true
                end

                context 'and #checked_but_not_custom_404?' do
                    context false do
                        before(:each) { subject.instance.stub(:checked_but_not_custom_404?) { false } }

                        it 'returns true' do
                            subject.needs_custom_404_check?( @url ).should be_true
                        end
                    end

                    context true do
                        before(:each) { subject.instance.stub(:checked_but_not_custom_404?) { true } }

                        it 'returns true' do
                            subject.needs_custom_404_check?( @url ).should be_true
                        end
                    end
                end
            end

            context true do
                before(:each) { subject.instance.stub(:checked_for_custom_404?) { true } }

                it 'returns true' do
                    subject.needs_custom_404_check?( @url ).should be_true
                end

                context 'and #checked_but_not_custom_404?' do
                    context true do
                        before(:each) { subject.instance.stub(:checked_but_not_custom_404?) { true } }

                        it 'returns false' do
                            subject.needs_custom_404_check?( @url ).should be_false
                        end
                    end

                    context false do
                        before(:each) { subject.instance.stub(:checked_but_not_custom_404?) { false } }

                        it 'returns true' do
                            subject.needs_custom_404_check?( @url ).should be_true
                        end
                    end
                end
            end
        end
    end

    describe '.info' do
        it 'returns a hash with an output name' do
            described_class.info[:name].should == 'HTTP'
        end
    end

end
