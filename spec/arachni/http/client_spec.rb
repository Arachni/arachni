# encoding: utf-8
require 'spec_helper'

describe Arachni::HTTP::Client do

    before( :all ) do
        @opts = Arachni::Options.instance
        @http = Arachni::HTTP::Client
        @url  = web_server_url_for( :client )
    end
    before( :each ){
        @opts.reset
        @opts.audit.links = true
        @opts.url  = @url
        @http.reset
    }

    it 'supports gzip content-encoding' do
        body = nil
        @http.get( @opts.url + 'gzip' ) { |res| body = res.body }
        @http.run
        body.should == 'success'
    end

    it 'preserves set-cookies' do
        body = nil
        @http.get( @opts.url + 'set_and_preserve_cookies', update_cookies: true )
        @http.run
        @http.cookies.first.value.should == "=stuf \00 here=="

        @http.get( @opts.url + 'cookies' ) { |res| body = res.body }
        @http.run
        YAML.load( body ).should == { 'stuff' => "=stuf \00 here==" }
    end

    describe 'Arachni::Options' do
        describe '#url' do
            context 'when the target URL includes auth credentials' do
                it 'uses them globally' do
                    # first fail to make sure that our test server is actually working properly
                    code = 0
                    @http.get( "#{@opts.url}auth/simple-chars" ) { |res| code = res.code }
                    @http.run
                    code.should == 401

                    url = Arachni::Utilities.uri_parse( "#{@opts.url}auth/simple-chars" )
                    url.user = 'username'
                    url.password = 'password'
                    @opts.url = url.to_s

                    body = nil
                    @http.get( @opts.url ) { |res| body = res.body }
                    @http.run
                    body.should == 'authenticated!'
                end
            end
        end

        describe '#http.request_concurrency' do
            context Integer do
                it 'uses it as a max_concurrency' do
                    @opts.http.request_concurrency = 34
                    @http.reset
                    @http.max_concurrency.should == 34
                end
            end
            context 'nil' do
                it 'uses a default max concurrency setting' do
                    @opts.http.request_concurrency = nil
                    @http.reset
                    @http.max_concurrency.should == Arachni::HTTP::Client::MAX_CONCURRENCY
                end
            end
        end

        describe '#http.request_timeout' do
            context Integer do
                it 'uses it as an HTTP timeout' do
                    @opts.http.request_timeout = 10000000000
                    timed_out = false
                    @http.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                    @http.run
                    timed_out.should be_false

                    @opts.http.request_timeout = 1
                    @http.reset
                    timed_out = false
                    @http.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                    @http.run
                    timed_out.should be_true
                end
            end
            context 'nil' do
                it 'uses a default timeout setting' do
                    timed_out = false
                    @http.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                    @http.run
                    timed_out.should be_false
                end
            end
        end

        describe '#http.authentication_username and #http.authentication_password' do
            it 'uses them globally' do
                Arachni::Options.http.authentication_username = 'username1'
                Arachni::Options.http.authentication_password = 'password1'

                # first fail to make sure that our test server is actually working properly
                code = 0
                @http.get( @opts.url + 'auth/weird-chars' ) { |res| code = res.code }
                @http.run
                code.should == 401

                Arachni::Options.http.authentication_username,
                    Arachni::Options.http.authentication_password =
                        ['u se rname$@#@#%$3#@%@#', 'p a  :wo\'rd$@#@#%$3#@%@#' ]

                response = nil
                @http.get( @opts.url + 'auth/weird-chars' ) { |res| response = res }
                @http.run
                response.code.should == 200
                response.body.should == 'authenticated!'
            end
        end

        describe 'Options#http.user_agent' do
            it 'uses the default user-agent setting' do
                body = nil
                @http.get( @opts.url + 'user-agent' ) { |res| body = res.body }
                @http.run

                body.should == @opts.http.user_agent
                @opts.http.user_agent.should == Arachni::OptionGroups::HTTP.defaults[:user_agent]
            end
            context String do
                it 'uses it as a user-agent' do
                    ua = 'my user agent'
                    @opts.http.user_agent = ua.dup
                    @http.reset

                    body = nil
                    @http.get( @opts.url + 'user-agent' ) { |res| body = res.body }
                    @http.run
                    body.should == ua
                end
            end
        end

        describe '#http.request_redirect_limit' do
            context Integer do
                it 'should not exceed that amount of redirects' do
                    @opts.http.request_redirect_limit = 2
                    code = nil
                    @http.get( @opts.url + 'redirect', follow_location: true ) { |res| code = res.code }
                    @http.run
                    code.should == 302

                    @opts.http.request_redirect_limit = 10
                    @http.reset

                    body = nil
                    @http.get( @opts.url + 'redirect', follow_location: true ) { |res| body = res.body }
                    @http.run
                    body.should == 'This is the end.'
                end
            end
            context 'nil' do
                it 'uses a default setting' do
                    @http.reset

                    body = nil
                    @http.get( @opts.url + 'redirect', follow_location: true ) { |res| body = res.body }
                    @http.run
                    body.should == 'This is the end.'
                end
            end
        end

        describe '#fingerprint?' do
            context true do
                it 'performs platform fingerprinting on the response' do
                    Arachni::Options.fingerprint

                    res = nil
                    @http.request( @url + '/fingerprint.php' ) { |c_res| res = c_res }
                    @http.run

                    res.platforms.to_a.should == [:php]
                end
            end

            context false do
                it 'does not fingerprint the response' do
                    Arachni::Platform::Manager.clear
                    Arachni::Options.do_not_fingerprint

                    res = nil
                    @http.request( @url + '/fingerprint.php' ) { |c_res| res = c_res }
                    @http.run

                    res.platforms.should be_empty
                end
            end
        end
    end

    describe '#sandbox' do
        it 'preserves state, runs the block and then restores state' do
            @http.cookies.should be_empty
            @http.get( @opts.url + 'set_and_preserve_cookies', update_cookies: true )
            @http.run
            @http.cookies.should be_any

            headers = @http.headers.dup

            signals = []
            @http.add_on_complete do |r|
                signals << :out
            end

            @http.get( @opts.url + 'out', mode: :sync )

            @http.sandbox do
                @http.cookies.should be_any
                @http.cookie_jar.clear
                @http.cookies.should be_empty

                @http.headers.should == headers
                @http.headers['X-Custom'] = 'stuff'
                @http.headers.include?( 'X-Custom' ).should be_true

                @http.add_on_complete do |r|
                    signals << :in
                end

                @http.get( @opts.url + 'in', mode: :sync )
            end

            @http.get( @opts.url + 'out', mode: :sync )

            signals.delete( :out )
            signals.size.should == 1

            @http.headers.include?( 'X-Custom' ).should be_false
            @http.cookies.should be_any
        end
    end

    describe '#url' do
        it 'returns the URL in opts' do
            @http.url.should == @opts.url.to_s
        end
    end

    describe '#headers' do
        it 'provides access to default headers' do
            headers = @http.headers
            headers['Accept'].should == 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
            headers['User-Agent'].should == 'Arachni/v' + Arachni::VERSION
        end

        context 'when Options#http_request_headers is set' do
            it 'includes them' do
                @opts.http.request_headers = {
                    'User-Agent' => 'My UA',
                    'From'       => 'Some dude',
                }
                @http.reset
                headers = @http.headers
                headers['From'].should == @opts.http.request_headers['From']
                headers['Accept'].should == 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
                headers['User-Agent'].should == @opts.http.request_headers['User-Agent']
            end
        end

        context 'when the authorized_by option is set' do
            it 'includes it in the From field' do
                @opts.authorized_by = 'The Dude'
                @http.reset
                @http.headers['From'].should == @opts.authorized_by
            end
        end
    end

    describe '#cookie_jar' do
        it 'provides access to the Cookie-jar' do
            @http.cookie_jar.is_a?( Arachni::HTTP::CookieJar ).should be_true
        end

        context 'when Options#http_cookie_jar_filepath is set' do
            it 'adds the contained cookies to the CookieJar' do
                @opts.http.cookie_jar_filepath = fixtures_path + 'cookies.txt'
                @http.cookie_jar.cookies.should be_empty
                @http.reset
                cookies = @http.cookie_jar.cookies
                cookies.size.should == 4
                cookies.should == Arachni::Utilities.cookies_from_file( '', @opts.http.cookie_jar_filepath )
            end
            context 'but the path is invalid' do
                it 'raises Arachni::HTTP::CookieJar::Error::CookieJarFileNotFound' do
                    @opts.http.cookie_jar_filepath = fixtures_path + 'cookies.does_not_exist.txt'
                    expect{ @http.reset }.to raise_error Arachni::HTTP::CookieJar::Error::CookieJarFileNotFound
                end
            end
        end

        context 'when the cookies option is set' do
            it 'adds those cookies to the CookieJar' do
                cookie_jar_file = fixtures_path + 'cookies.txt'
                @opts.http.cookies = Arachni::Utilities.cookies_from_file( '', cookie_jar_file )
                @http.cookie_jar.cookies.should be_empty
                @http.reset
                cookies = @http.cookie_jar.cookies
                cookies.size.should == 4
                cookies.should == @opts.http.cookies
            end
        end

        context 'when Options#http_cookie_string is set' do
            it 'parses the string and add those cookies to the CookieJar' do
                @opts.http.cookie_string = 'my_cookie_name=val1;blah_name=val2; stuff=%25blah; another_name=another_val'
                @http.cookie_jar.cookies.should be_empty
                @http.reset
                cookies = @http.cookie_jar.cookies
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
            @http.cookie_jar.cookies.should be_empty
            @http.reset
            @http.cookies.size.should == 3
            @http.cookies.should == @http.cookie_jar.cookies
        end
    end

    describe '#after_run' do
        it 'sets blocks to be called after #run' do
            called = false
            @http.after_run { called = true }
            @http.run
            called.should be_true

            called = false
            @http.run
            called.should be_false
        end

        context 'when the callback creates new requests and nested callbacks' do
            it 'run these too' do
                called = false
                @http.after_run do
                    @http.after_run { called = true }
                end
                @http.run
                called.should be_false

                called = false
                @http.after_run do
                    @http.get
                    @http.after_run { called = true }
                end
                @http.run
                called.should be_true

                called = false
                @http.run
                called.should be_false
            end
        end
    end

    describe '#run' do
        it 'performs the queues requests' do
            @http.run
        end


        it 'calls the after_run_persistent callbacks EVERY TIME' do
            called = false
            @http.after_run_persistent { called = true }
            @http.run
            called.should be_true
            called = false
            @http.run
            called.should be_true
        end

        it 'calculates the burst average response time' do
            @http.run
            @http.burst_runtime.should > 0
        end

        it 'updates burst_response_time_sum, burst_response_count,' +
               ' burst_average_response_time and burst_responses_per_second' +
               ' during runtime and resets them afterwards' do
            @http.total_runtime.to_i.should          == 0
            @http.total_average_response_time.should == 0
            @http.total_responses_per_second.should  == 0

            @http.burst_response_time_sum.should     == 0
            @http.burst_response_count.should        == 0
            @http.burst_average_response_time.should == 0
            @http.burst_responses_per_second.should  == 0

            total_runtime               = 0
            total_average_response_time = 0
            total_responses_per_second  = 0

            burst_response_time_sum     = 0
            burst_response_count        = 0
            burst_average_response_time = 0
            burst_responses_per_second  = 0

            20.times do
                @http.get do
                    total_runtime               = @http.total_runtime
                    total_average_response_time = @http.total_average_response_time
                    total_responses_per_second  = @http.total_responses_per_second

                    burst_response_time_sum     = @http.burst_response_time_sum
                    burst_response_count        = @http.burst_response_count
                    burst_average_response_time = @http.burst_average_response_time
                    burst_responses_per_second  = @http.burst_responses_per_second
                end
            end

            @http.run

            total_runtime.should               > 0
            total_average_response_time.should > 0
            total_responses_per_second.should  > 0

            burst_response_time_sum.should     > 0
            burst_response_count.should        > 0
            burst_average_response_time.should > 0
            burst_responses_per_second.should  > 0
        end
    end

    describe '#abort' do
        it 'aborts the running requests on a best effort basis' do
            cnt = 0
            n = 50
            n.times do |i|
                @http.get {
                    cnt += 1
                    @http.abort
                }
            end
            @http.run
            cnt.should < n
        end
    end

    describe '#max_concurrency' do
        it 'defaults to 20' do
            @http.max_concurrency.should == 20
        end
        it 'respects the http_request_concurrency option' do
            @opts.http.request_concurrency = 50
            @http.reset
            @http.max_concurrency.should == 50
        end
    end

    describe '#max_concurrency=' do
        it 'sets the max_concurrency setting' do
            @http.max_concurrency.should_not == 30
            @http.max_concurrency = 30
            @http.max_concurrency.should == 30
        end
    end

    describe '#request' do
        it 'uses the URL in Arachni::Options.instance.url as a default' do
            url = nil
            @http.request{ |res| url = res.url }
            @http.run
            url.start_with?( @opts.url.to_s ).should be_true
        end

        it 'raises exception when no URL is available' do
            @opts.reset
            @http.reset
            expect { @http.request }.to raise_error
        end

        it "fills in #{Arachni::HTTP::Request}#headers_string" do
            host = "#{Arachni::URI(@url).host}:#{Arachni::URI(@url).port}"
            @http.request( @url, mode: :sync ).request.headers_string.should ==
                "GET / HTTP/1.1\r\nHost: #{host}\r\nAccept-Encoding: gzip, " +
                    "deflate\r\nUser-Agent: Arachni/v1.0dev\r\nAccept: text/html," +
                    "application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n\r\n"
        end

        it "fills in #{Arachni::HTTP::Request}#effective_body" do
            @http.request( @url,
               body: {
                   '1' => ' 2',
                   ' 3' => '4'
               },
               mode:   :sync,
               method: :post
            ).request.effective_body.should == "1=%202&%203=4"
        end

        describe :response_max_size do
            context 'when Options#http_response_max_size is specified' do
                it 'ignores bodies of responses which are larger than specified' do
                    @opts.http.response_max_size = 0
                    @http.request( @url + '/http_response_max_size',
                                   mode: :sync
                    ).body.should be_empty

                    @opts.http.response_max_size = 1
                    @http.request( @url + '/http_response_max_size',
                                   mode: :sync
                    ).body.should be_empty

                    @opts.http.response_max_size = 999999
                    @http.request( @url + '/http_response_max_size',
                                   mode: :sync
                    ).body.should be_empty

                    @opts.http.response_max_size = 1000000
                    @http.request( @url + '/http_response_max_size',
                                   mode: :sync
                    ).body.should_not be_empty
                end
            end

            context 'when specified' do
                it 'ignores bodies of responses which are larger than specified' do
                    @http.request( @url + '/http_response_max_size',
                                   mode: :sync,
                                   response_max_size: 0
                    ).body.should be_empty

                    @http.request( @url + '/http_response_max_size',
                                   mode: :sync,
                                   response_max_size: 1
                    ).body.should be_empty

                    @http.request( @url + '/http_response_max_size',
                                   mode: :sync,
                                   response_max_size: 999999
                    ).body.should be_empty

                    @http.request( @url + '/http_response_max_size',
                                   mode: :sync,
                                   response_max_size: 1000000
                    ).body.should_not be_empty
                end
            end

            context 'by default' do
                it 'does not enforce a limit' do
                    @http.request( @url + '/http_response_max_size',
                                   mode: :sync
                    ).body.should_not be_empty
                end
            end
        end

        describe :no_cookiejar do
            context true do
                it 'skips the cookie-jar' do
                    body = nil
                    @http.request( @url + '/cookies', no_cookiejar: true ) { |res| body = res.body }
                    @http.run
                    YAML.load( body ).should == {}
                end
            end
            context false do
                it 'uses the cookiejar' do
                    @opts.http.cookie_string = 'my_cookie_name=val1;blah_name=val2;another_name=another_val'
                    @http.cookie_jar.cookies.should be_empty
                    @http.reset

                    body = nil

                    @http.request( @url + '/cookies', no_cookiejar: false ) { |res| body = res.body }
                    @http.run
                    YAML.load( body ).should == {
                        'my_cookie_name' => 'val1',
                        'blah_name' => 'val2',
                        'another_name' => 'another_val'
                    }
                end
                context 'when custom cookies are provided' do
                    it 'merges them with the cookiejar and override it' do
                        @opts.http.cookie_string = 'my_cookie_name=val1;blah_name=val2;another_name=another_val'
                        @http.cookie_jar.cookies.should be_empty
                        @http.reset

                        body = nil

                        custom_cookies = { 'newcookie' => 'newval', 'blah_name' => 'val3' }
                        @http.request( @url + '/cookies', cookies: custom_cookies,
                                       no_cookiejar: false ) { |res| body = res.body }
                        @http.run
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
                    @http.cookie_jar.cookies.should be_empty
                    @http.reset

                    body = nil

                    @http.request( @url + '/cookies' ) { |res| body = res.body }
                    @http.run
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
                @http.request( @url + '/body', method: :post, body: req_body ) { |res| body = res.body }
                @http.run
                body.should == req_body
            end
        end

        describe :method do
            describe 'nil' do
                it 'performs a GET HTTP request' do
                    body = nil
                    @http.request( @url ) { |res| body = res.body }
                    @http.run
                    body.should == 'GET'
                end
            end
            describe :get do
                it 'performs a GET HTTP request' do
                    body = nil
                    @http.request( @url, method: :get ) { |res| body = res.body }
                    @http.run
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
                        @http.request( url, parameters: params, method: :get ){ |res| body = res.body }
                        @http.run
                        YAML.load( body ).should eq params.merge( 'param3' => 'value3' )
                    end
                end
            end
            describe :post do
                it 'performs a POST HTTP request' do
                    body = nil
                    @http.request( @url, method: :post ) { |res| body = res.body }
                    @http.run
                    body.should == 'POST'
                end
            end
            describe :put do
                it 'performs a PUT HTTP request' do
                    body = nil
                    @http.request( @url, method: :put ) { |res| body = res.body }
                    @http.run
                    body.should == 'PUT'
                end
            end
            describe :options do
                it 'performs a OPTIONS HTTP request' do
                    body = nil
                    @http.request( @url, method: :options ) { |res| body = res.body }
                    @http.run
                    body.should == 'OPTIONS'
                end
            end
            describe :delete do
                it 'performs a POST HTTP request' do
                    body = nil
                    @http.request( @url, method: :delete ) { |res| body = res.body }
                    @http.run
                    body.should == 'DELETE'
                end
            end
        end

        describe :parameters do
            it 'specifies the query params as a hash' do
                body = nil
                params = { 'param' => 'value' }
                @http.request( @url + '/echo', parameters: params ) { |res| body = res.body }
                @http.run
                params.should eq YAML.load( body )
            end

            it 'preserves nullbytes' do
                body = nil
                params = { "pa\0ram" => "v\0alue" }
                @http.request( @url + '/echo', parameters: params ) { |res| body = res.body }
                @http.run
                params.should eq YAML.load( body )
            end
        end

        describe :body do
            it 'properly encodes special characters' do
                body = nil
                params = { '% param\ +=&;' => '% value\ +=&;', 'nil' => nil }
                @http.request( @url + '/echo', method: :post, body: params ) { |res| body = res.body }
                @http.run
                YAML.load( body ).should == { '% param\ +=&;' => '% value\ +=&;', 'nil' => '' }
            end

            it 'preserves nullbytes' do
                body = nil
                params = { "st\0uff" => "test\0" }
                @http.request( @url + '/echo', method: :post, body: params, ) { |res| body = res.body }
                @http.run
                YAML.load( body ).should == params
            end
        end

        describe :timeout do
            describe 'nil' do
                it 'runs without a timeout' do
                    timed_out = false
                    @http.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                    @http.run
                    timed_out.should be_false
                end
            end
            describe Numeric do
                it 'sets a timeout value in milliseconds' do
                    timed_out = false
                    @http.request( @url + '/sleep', timeout: 4_000 ) { |res| timed_out = res.timed_out? }
                    @http.run
                    timed_out.should be_true

                    timed_out = false
                    @http.request( @url + '/sleep', timeout: 6_000 ) { |res| timed_out = res.timed_out? }
                    @http.run
                    timed_out.should be_false
                end
            end
        end

        describe ':username/:password' do
            it 'uses them to authenticate' do
                # first fail to make sure that our test server is actually working properly
                code = 0
                @http.get( @opts.url + 'auth/weird-chars' ) { |res| code = res.code }
                @http.run
                code.should == 401

                response = nil
                @http.get(
                    @opts.url + 'auth/weird-chars',
                    username: 'u se rname$@#@#%$3#@%@#',
                    password: 'p a  :wo\'rd$@#@#%$3#@%@#' ) { |res| response = res }
                @http.run
                response.code.should == 200
                response.body.should == 'authenticated!'
            end
        end

        describe :cookies do
            describe 'nil' do
                it 'uses te cookies in the CookieJar' do
                    @opts.http.cookie_string = 'my_cookie_name=val1;blah_name=val2;another_name=another_val'
                    @http.cookie_jar.cookies.should be_empty
                    @http.reset

                    body = nil
                    @http.request( @url + '/cookies' ) { |res| body = res.body }
                    @http.run
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

                    @http.cookie_jar.update( cookies )
                    body = nil
                    @http.request( @url + '/cookies' ) { |res| body = res.body }
                    @http.run
                    YAML.load( body ).should == { 'key2' => 'val2' }
                end
            end
            describe Hash do
                it 'uses the key-value pairs as cookies' do
                    cookies = { 'name' => 'val' }
                    body = nil
                    @http.request( @url + '/cookies', cookies: cookies ) { |res| body = res.body }
                    @http.run
                    YAML.load( body ).should == cookies
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
                        @http.request( @url + '/cookies', options ) { |res| body = res.body }
                        @http.run

                        YAML.load( body ).should == { 'test' => '1', 'name' => 'val' }
                    end
                end
            end

            it 'preserves nullbytess' do
                cookies = { "name\0" => "val\0" }
                body = nil
                @http.request( @url + '/cookies', cookies: cookies ) { |res| body = res.body }
                @http.run
                YAML.load( body ).should == cookies
            end

        end

        describe :mode do
            describe 'nil' do
                it 'performs the request asynchronously' do
                    performed = false
                    @http.request( @url ) { performed = true }
                    @http.run
                    performed.should be_true
                end
            end
            describe :async do
                it 'performs the request asynchronously' do
                    performed = false
                    @http.request( @url, mode: :sync ) { performed = true }
                    @http.run
                    performed.should be_true
                end
            end
            describe :sync do
                it 'performs the request synchronously and returns the response' do
                    @http.request( @url, mode: :sync ).should be_kind_of Arachni::HTTP::Response
                end

                it 'assigns a #request to the returned response' do
                    @http.request( @url, mode: :sync ).request.should be_kind_of Arachni::HTTP::Request
                end

                context 'when a block is given' do
                    it 'passes the response to it as well' do
                        called = []
                        response = @http.request( @url, mode: :sync ) do |r|
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
                    @http.request( @url + '/headers' ) { |res| body = res.body }
                    @http.run
                    sent_headers = YAML.load( body )
                    @http.headers.each { |k, v| sent_headers[k].should == v }
                end
            end

            describe Hash do
                it 'merges them with the default headers' do
                    headers = { 'My-Header' => 'my value'}
                    body = nil
                    @http.request( @url + '/headers', headers: headers ) { |res| body = res.body }
                    @http.run
                    sent_headers = YAML.load( body )
                    @http.headers.merge( headers ).each { |k, v| sent_headers[k].should == v }
                end
            end
        end

        describe :update_cookies do
            describe 'nil' do
                it 'skips the cookiejar' do
                    cookies = []
                    cookies << Arachni::Element::Cookie.new(
                        url: @url,
                        inputs: { 'key2' => 'val2' }
                    )
                    @http.update_cookies( cookies )
                    @http.request( @url + '/update_cookies' )
                    @http.run
                    @http.cookies.should == cookies
                end
            end

            describe false do
                it 'skips the cookiejar' do
                    cookies = []
                    cookies << Arachni::Element::Cookie.new(
                        url: @url,
                        inputs: { 'key2' => 'val2' }
                    )
                    @http.update_cookies( cookies )
                    @http.request( @url + '/update_cookies', update_cookies: false )
                    @http.run
                    @http.cookies.should == cookies
                end
            end

            describe true do
                it 'updates the cookiejar' do
                    cookies = []
                    cookies << Arachni::Element::Cookie.new(
                        url:    @url,
                        name:   'key2',
                        value:  'val2',
                        domain: Arachni::URI( @url ).domain
                    )
                    @http.update_cookies( cookies )
                    @http.request( @url + '/update_cookies', update_cookies: true )
                    @http.run
                    @http.cookies.first.value.should == cookies.first.value + ' [UPDATED!]'
                end
            end
        end

        describe :follow_location do
            describe 'nil' do
                it 'ignores redirects' do
                    res = nil
                    @http.request( @url + '/follow_location' ) { |c_res| res = c_res }
                    @http.run
                    res.url.start_with?( @url + '/follow_location' ).should be_true
                    res.body.should == ''
                end
            end
            describe false do
                it 'ignores redirects' do
                    res = nil
                    @http.request( @url + '/follow_location', follow_location: false ) { |c_res| res = c_res }
                    @http.run
                    res.url.start_with?( @url + '/follow_location' ).should be_true
                    res.body.should == ''
                end
            end
            describe true do
                it 'follows redirects' do
                    res = nil
                    @http.request( @url + '/follow_location', follow_location: true ) { |c_res| res = c_res }
                    @http.run
                    res.url.should == @url + '/redir_2'
                    res.body.should == "Welcome to redir_2!"
                end
            end
        end
    end

    describe '#get' do
        it 'performs a GET request' do
            body = nil
            @http.get { |res| body = res.body }
            @http.run
            body.should == 'GET'
        end
    end

    describe '#post' do
        it 'performs a POST request' do
            body = nil
            @http.post { |res| body = res.body }
            @http.run
            body.should == 'POST'
        end

        it 'passes :parameters as a #request :body' do
            body = nil
            params = { '% param\ +=&;' => '% value\ +=&;', 'nil' => nil }
            @http.post( @url + '/echo', parameters: params ) { |res| body = res.body }
            @http.run
            YAML.load( body ).should == { '% param\ +=&;' => '% value\ +=&;', 'nil' => '' }
        end
    end

    describe '#cookie' do
        it 'performs a GET request' do
            body = nil
            cookies = { 'name' => "v%+;al\00=" }
            @http.cookie( @url + '/cookies', parameters: cookies ) { |res| body = res.body }
            @http.run
            YAML.load( body ).should == cookies
        end
    end

    describe '#headers' do
        it 'performs a GET request' do
            body = nil
            headers = { 'name' => 'val' }
            @http.header( @url + '/headers', parameters: headers ) { |res| body = res.body }
            @http.run
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

            @http.queue request
            @http.run

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

            @http.cookies.should be_empty
            @http.update_cookies( cookies )
            @http.cookies.should == cookies
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
            @http.on_new_cookies do |cookies, res|
                callback_cookies  = cookies
                callback_response = res
            end
            @http.parse_and_set_cookies( res )

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
            @http.cookies.should be_empty
            @http.parse_and_set_cookies( res )
            @http.cookies.should == cookies
        end
    end

    describe '#custom_404?' do
        before { @custom_404 = @url + '/custom_404/' }

        context 'when not dealing with a custom 404 handler' do
            it 'returns false' do
                res = nil
                @http.get( @custom_404 + 'not' ) { |c_res| res = c_res }
                @http.run
                bool = false
                @http.custom_404?( res ) { |c_bool| bool = c_bool }
                @http.run
                bool.should be_false
            end
        end

        context 'when dealing with a static handler' do
            it 'returns true' do
                res = nil
                @http.get( @custom_404 + 'static/crap' ) { |c_res| res = c_res }
                @http.run
                bool = false
                @http.custom_404?( res ) { |c_bool| bool = c_bool }
                @http.run
                bool.should be_true
            end
        end

        context 'when dealing with a dynamic handler' do
            context 'which includes the requested resource in the response' do
                it 'returns true' do
                    res = nil
                    @http.get( @custom_404 + 'dynamic/crap' ) { |c_res| res = c_res }
                    @http.run
                    bool = false
                    @http.custom_404?( res ) { |c_bool| bool = c_bool }
                    @http.run
                    bool.should be_true
                end
            end
            context 'which includes constantly changing text in the response' do
                it 'returns true' do
                    res = nil
                    @http.get( @custom_404 + 'random/crap' ) { |c_res| res = c_res }
                    @http.run
                    bool = false
                    @http.custom_404?( res ) { |c_bool| bool = c_bool }
                    @http.run
                    bool.should be_true
                end
            end
            context 'which returns a combination of the above' do
                it 'returns true' do
                    res = nil
                    @http.get( @custom_404 + 'combo/crap' ) { |c_res| res = c_res }
                    @http.run
                    bool = false
                    @http.custom_404?( res ) { |c_bool| bool = c_bool }
                    @http.run
                    bool.should be_true
                end
            end
        end
    end

end
