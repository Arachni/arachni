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
        expect(body).to eq('success')
    end

    it 'preserves set-cookies' do
        body = nil
        subject.get( @opts.url + 'set_and_preserve_cookies', update_cookies: true )
        subject.run
        expect(subject.cookies.first.value).to eq("=stuf \00 here==")

        subject.get( @opts.url + 'cookies' ) { |res| body = res.body }
        subject.run
        expect(YAML.load( body )).to eq({ 'stuff' => "=stuf \00 here==" })
    end

    describe '#reset_options' do
        it 'resets #max_concurrency' do
            Arachni::Options.http.request_concurrency = 10
            subject.max_concurrency = 1

            subject.reset_options
            expect(subject.max_concurrency).to eq 10
        end

        it 'resets User-Agent headers' do
            Arachni::Options.http.user_agent = 'Stuff'
            subject.headers['User-Agent'] = 'Other stuff'

            subject.reset_options
            expect(subject.headers['User-Agent']).to eq 'Stuff'
        end

        it 'resets custom headers' do
            Arachni::Options.http.request_headers = {
                'X-Stuff' => '1'
            }
            subject.headers['X-Stuff'] = '2'

            subject.reset_options
            expect(subject.headers['X-Stuff']).to eq '1'
        end

        it 'clears custom headers' do
            subject.headers['X-Stuff'] = '2'

            subject.reset_options
            expect(subject.headers).to_not include 'X-Stuff'
        end
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        [:request_count, :response_count, :time_out_count,
         :total_responses_per_second, :burst_response_time_sum,
         :burst_response_count, :burst_responses_per_second,
         :burst_average_response_time, :total_average_response_time,
         :original_max_concurrency, :max_concurrency].each do |k|
            it "includes #{k}" do
                expect(statistics[k]).to eq(subject.send(k))
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
                    expect(code).to eq(401)

                    url = Arachni::Utilities.uri_parse( "#{@opts.url}auth/simple-chars" )
                    url.userinfo = 'username:password'
                    @opts.url = url.to_s

                    body = nil
                    subject.get( @opts.url ) { |res| body = res.body }
                    subject.run
                    expect(body).to eq('authenticated!')
                end
            end
        end

        describe '#fingerprint?' do
            context 'true' do
                it 'performs platform fingerprinting on the response' do
                    Arachni::Options.fingerprint

                    res = nil
                    subject.request( @url + '/fingerprint.php' ) { |c_res| res = c_res }
                    subject.run

                    expect(res.platforms.to_a).to eq([:php])
                end
            end

            context 'false' do
                it 'does not fingerprint the response' do
                    Arachni::Platform::Manager.clear
                    Arachni::Options.do_not_fingerprint

                    res = nil
                    subject.request( @url + '/fingerprint.php' ) { |c_res| res = c_res }
                    subject.run

                    expect(res.platforms).to be_empty
                end
            end
        end
    end

    describe Arachni::OptionGroups::HTTP do
        describe '#request_concurrency' do
            context 'Integer' do
                it 'uses it as a max_concurrency' do
                    @opts.http.request_concurrency = 34
                    subject.reset
                    expect(subject.max_concurrency).to eq(34)
                end
            end
            context 'nil' do
                it 'uses a default max concurrency setting' do
                    @opts.http.request_concurrency = nil
                    subject.reset
                    expect(subject.max_concurrency).to eq(Arachni::HTTP::Client::MAX_CONCURRENCY)
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

                    expect(responses.size).to eq(10)

                    subject.run
                    expect(responses.size).to eq(11)
                end
            end
        end

        describe '#request_timeout' do
            context 'Integer' do
                it 'uses it as an HTTP timeout' do
                    @opts.http.request_timeout = 10000000000
                    timed_out = false
                    subject.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                    subject.run
                    expect(timed_out).to be_falsey

                    @opts.http.request_timeout = 1
                    subject.reset
                    timed_out = false
                    subject.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                    subject.run
                    expect(timed_out).to be_truthy
                end
            end
            context 'nil' do
                it 'uses a default timeout setting' do
                    timed_out = false
                    subject.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                    subject.run
                    expect(timed_out).to be_falsey
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
                expect(code).to eq(401)

                Arachni::Options.http.authentication_username,
                    Arachni::Options.http.authentication_password =
                        ['u se rname$@#@#%$3#@%@#', 'p a  :wo\'rd$@#@#%$3#@%@#' ]

                response = nil
                subject.get( @opts.url + 'auth/weird-chars' ) { |res| response = res }
                subject.run
                expect(response.code).to eq(200)
                expect(response.body).to eq('authenticated!')
            end
        end

        describe 'user_agent' do
            it 'uses the default user-agent setting' do
                body = nil
                subject.get( @opts.url + 'user-agent' ) { |res| body = res.body }
                subject.run

                expect(body).to eq(@opts.http.user_agent)
                expect(@opts.http.user_agent).to eq(Arachni::OptionGroups::HTTP.defaults[:user_agent])
            end
            context 'String' do
                it 'uses it as a user-agent' do
                    ua = 'my user agent'
                    @opts.http.user_agent = ua.dup
                    subject.reset

                    body = nil
                    subject.get( @opts.url + 'user-agent' ) { |res| body = res.body }
                    subject.run
                    expect(body).to eq(ua)
                end
            end
        end

        describe '#request_redirect_limit' do
            context 'Integer' do
                it 'should not exceed that amount of redirects' do
                    @opts.http.request_redirect_limit = 2
                    code = nil
                    subject.get( @opts.url + 'redirect', follow_location: true ) { |res| code = res.code }
                    subject.run
                    expect(code).to eq(302)

                    @opts.http.request_redirect_limit = 10
                    subject.reset

                    body = nil
                    subject.get( @opts.url + 'redirect', follow_location: true ) { |res| body = res.body }
                    subject.run
                    expect(body).to eq('This is the end.')
                end
            end
            context 'nil' do
                it 'uses a default setting' do
                    subject.reset

                    body = nil
                    subject.get( @opts.url + 'redirect', follow_location: true ) { |res| body = res.body }
                    subject.run
                    expect(body).to eq('This is the end.')
                end
            end
        end
    end

    describe '#sandbox' do
        it 'preserves state, runs the block and then restores state' do
            expect(subject.cookies).to be_empty
            subject.get( @opts.url + 'set_and_preserve_cookies', update_cookies: true )
            subject.run
            expect(subject.cookies).to be_any

            headers = subject.headers.dup

            signals = []
            subject.on_complete do |r|
                signals << :out
            end

            subject.get( @opts.url + 'out', mode: :sync )

            subject.sandbox do
                expect(subject.cookies).to be_any
                subject.cookie_jar.clear
                expect(subject.cookies).to be_empty

                expect(subject.headers).to eq(headers)
                subject.headers['X-Custom'] = 'stuff'
                expect(subject.headers.include?( 'X-Custom' )).to be_truthy

                subject.on_complete do |r|
                    signals << :in
                end

                subject.get( @opts.url + 'in', mode: :sync )
            end

            subject.get( @opts.url + 'out', mode: :sync )

            signals.delete( :out )
            expect(signals.size).to eq(1)

            expect(subject.headers.include?( 'X-Custom' )).to be_falsey
            expect(subject.cookies).to be_any
        end
    end

    describe '#url' do
        it 'returns the URL in opts' do
            expect(subject.url).to eq(@opts.url.to_s)
        end
    end

    describe '#headers' do
        it 'provides access to default headers' do
            headers = subject.headers
            expect(headers['Accept']).to eq('text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8')
            expect(headers['User-Agent']).to eq('Arachni/v' + Arachni::VERSION)
        end

        context "when #{Arachni::OptionGroups::HTTP}#request_headers is set" do
            it 'includes them' do
                @opts.http.request_headers = {
                    'User-Agent' => 'My UA',
                    'From'       => 'Some dude',
                }
                subject.reset
                headers = subject.headers
                expect(headers['From']).to eq(@opts.http.request_headers['From'])
                expect(headers['Accept']).to eq('text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8')
                expect(headers['User-Agent']).to eq(@opts.http.request_headers['User-Agent'])
            end
        end

        context 'when the authorized_by option is set' do
            it 'includes it in the From field' do
                @opts.authorized_by = 'The Dude'
                subject.reset
                expect(subject.headers['From']).to eq(@opts.authorized_by)
            end
        end
    end

    describe '#cookie_jar' do
        it 'provides access to the Cookie-jar' do
            expect(subject.cookie_jar.is_a?( Arachni::HTTP::CookieJar )).to be_truthy
        end

        context "when #{Arachni::OptionGroups::HTTP}#cookie_jar_filepath is set" do
            it 'adds the contained cookies to the CookieJar' do
                @opts.http.cookie_jar_filepath = fixtures_path + 'cookies.txt'
                expect(subject.cookie_jar.cookies).to be_empty
                subject.reset
                cookies = subject.cookie_jar.cookies
                expect(cookies.size).to eq(4)
                expect(cookies).to eq(Arachni::Utilities.cookies_from_file( '', @opts.http.cookie_jar_filepath ))
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
                @opts.http.cookies = {
                    'cookie1' => 'val1',
                    'cookie2' => 'val2',
                }

                expect(subject.cookie_jar.cookies).to be_empty

                subject.reset

                cookies = subject.cookie_jar.cookies
                expect(cookies.size).to eq(2)

                expect(cookies[0].inputs).to eq({ 'cookie1' => 'val1' })
                expect(cookies[1].inputs).to eq({ 'cookie2' => 'val2' })
            end
        end

        context "when #{Arachni::OptionGroups::HTTP}#cookie_string is set" do
            it 'parses the string and add those cookies to the CookieJar' do
                @opts.http.cookie_string = 'my_cookie_name=val1;path=/my/path,blah_name=val2, stuff=%25blah, another_name=another_val'
                expect(subject.cookie_jar.cookies).to be_empty
                subject.reset
                cookies = subject.cookie_jar.cookies
                expect(cookies.size).to eq(4)
                expect(cookies.first.name).to eq('my_cookie_name')
                expect(cookies.first.value).to eq('val1')
                expect(cookies.first.path).to eq('/my/path')
                expect(cookies[1].name).to eq('blah_name')
                expect(cookies[1].value).to eq('val2')
                expect(cookies[2].name).to eq('stuff')
                expect(cookies[2].value).to eq('%blah')
                expect(cookies.last.name).to eq('another_name')
                expect(cookies.last.value).to eq('another_val')
            end
        end
    end

    describe '#cookies' do
        it 'returns the current cookies' do
            @opts.http.cookie_string = 'my_cookie_name=val1,blah_name=val2, another_name=another_val'
            expect(subject.cookie_jar.cookies).to be_empty
            subject.reset
            expect(subject.cookies.size).to eq(3)
            expect(subject.cookies).to eq(subject.cookie_jar.cookies)
        end
    end

    describe '#after_run' do
        it 'sets blocks to be called after #run' do
            called = false
            subject.after_run { called = true }
            subject.run
            expect(called).to be_truthy

            called = false
            subject.run
            expect(called).to be_falsey
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
                expect(called).to be_truthy

                called = false
                subject.run
                expect(called).to be_falsey
            end
        end

        context 'when the callback creates new callbacks' do
            it 'run these too' do
                called = false
                subject.after_run do
                    subject.after_run { called = true }
                end
                subject.run
                expect(called).to be_truthy
            end
        end
    end

    describe '#run' do
        it 'performs the queued requests' do
            response = nil
            subject.request { |r| response = r }

            subject.run

            expect(response).to be_kind_of Arachni::HTTP::Response
        end

        it 'returns true' do
            expect(subject.run).to be_truthy
        end

        it 'calls the after_each_run callbacks EVERY TIME' do
            called = false
            subject.after_each_run { called = true }
            subject.run
            expect(called).to be_truthy
            called = false
            subject.run
            expect(called).to be_truthy
        end

        it 'calculates the burst average response time' do
            subject.run
            expect(subject.burst_runtime).to be > 0
        end

        it 'updates burst_response_time_sum, burst_response_count,' +
               ' burst_average_response_time and burst_responses_per_second' +
               ' during runtime and resets them afterwards' do
            expect(subject.total_runtime.to_i).to          eq(0)
            expect(subject.total_average_response_time).to eq(0)
            expect(subject.total_responses_per_second).to  eq(0)

            expect(subject.burst_response_time_sum).to     eq(0)
            expect(subject.burst_response_count).to        eq(0)
            expect(subject.burst_average_response_time).to eq(0)
            expect(subject.burst_responses_per_second).to  eq(0)

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

            expect(total_runtime).to               be > 0
            expect(total_average_response_time).to be > 0
            expect(total_responses_per_second).to  be > 0

            expect(burst_response_time_sum).to     be > 0
            expect(burst_response_count).to        be > 0
            expect(burst_average_response_time).to be > 0
            expect(burst_responses_per_second).to  be > 0
        end

        context "when a #{RuntimeError} occurs" do
            it 'returns nil' do
                allow(subject.instance).to receive(:client_run){ raise }

                expect(subject.run).to be_nil
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
            expect(cnt).to be < n
        end
    end

    describe '#original_max_concurrency' do
        it 'returns the original max concurrency' do
            expect(subject.original_max_concurrency).to eq(20)
            expect(subject.original_max_concurrency).to eq(subject.max_concurrency)

            subject.max_concurrency = 10
            expect(subject.original_max_concurrency).to eq(20)
        end
    end

    describe '#max_concurrency' do
        it 'defaults to 20' do
            expect(subject.max_concurrency).to eq(20)
        end
        it 'respects the http_request_concurrency option' do
            @opts.http.request_concurrency = 50
            subject.reset
            expect(subject.max_concurrency).to eq(50)
        end
    end

    describe '#max_concurrency=' do
        it 'sets the max_concurrency setting' do
            expect(subject.max_concurrency).not_to eq(30)
            subject.max_concurrency = 30
            expect(subject.max_concurrency).to eq(30)
        end
    end

    describe '#request' do
        it "uses the URL in #{Arachni::Options}#url as a default" do
            url = nil
            subject.request{ |res| url = res.url }
            subject.run
            expect(url.start_with?( @opts.url.to_s )).to be_truthy
        end

        it 'raises exception when no URL is available' do
            @opts.reset
            subject.reset
            expect { subject.request }.to raise_error
        end

        it "fills in #{Arachni::HTTP::Request}#headers_string" do
            host = "#{Arachni::URI(@url).host}:#{Arachni::URI(@url).port}"
            expect(subject.request( @url, mode: :sync ).request.headers_string).to eq(
                "GET / HTTP/1.1\r\nHost: #{host}\r\nAccept-Encoding: gzip, " +
                    "deflate\r\nUser-Agent: Arachni/v#{Arachni::VERSION}\r\nAccept: text/html," +
                    "application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n" +
                    "Accept-Language: en-US,en;q=0.8,he;q=0.6\r\n" +
                    "X-Arachni-Scan-Seed: #{Arachni::Utilities.random_seed}\r\n\r\n"
            )
        end

        it "fills in #{Arachni::HTTP::Request}#effective_body" do
            expect(subject.request( @url,
               body: {
                   '1' => ' 2',
                   ' 3' => '4'
               },
               mode:   :sync,
               method: :post
            ).request.effective_body).to eq("1=%202&%203=4")
        end

        describe ':on_headers' do
            it 'gets called when headers are available' do
                h = nil

                subject.request(
                    "#{@url}/fast_stream",
                    mode: :sync,
                    on_headers: proc do |response|
                        h = response.to_h
                    end
                )

                expect(h[:code]).to eq 200
                expect(h[:body]).to eq ''
                expect(h[:headers]).to be_any
            end
        end

        describe ':on_body' do
            it 'gets called with body chunks' do
                chunks = []

                subject.request(
                    "#{@url}/fast_stream",
                    mode:    :sync,
                    on_body: proc do |chunk|
                        chunks << chunk
                    end
                )

                expect(chunks.size).to be == 5
            end
        end

        describe ':on_body_line' do
            it 'gets called with body lines' do
                lines = []

                subject.request(
                    "#{@url}/fast_stream",
                    mode:         :sync,
                    on_body_line: proc do |line|
                        lines << line
                    end
                )

                expect(lines.size).to be == 5
            end
        end

        describe ':on_body_lines' do
            it 'gets called with chunks of body lines' do
                lines = []

                subject.request(
                    "#{@url}/lines/non-stream",
                    mode:         :sync,
                    on_body_lines: proc do |line|
                        lines << line
                    end
                )

                expect(lines.size).to be > 1
                expect(lines.size).to be < 500
            end
        end

        describe ':fingerprint' do
            before do
                Arachni::Platform::Manager.clear
            end

            context 'nil' do
                it 'performs platform fingerprinting on the response' do
                    res = nil
                    subject.request( @url + '/fingerprint.php' ) { |c_res| res = c_res }
                    subject.run

                    expect(res.platforms.to_a).to eq([:php])
                end
            end

            context 'true' do
                it 'performs platform fingerprinting on the response' do
                    res = nil
                    subject.request( @url + '/fingerprint.php', fingerprint: true ) { |c_res| res = c_res }
                    subject.run

                    expect(res.platforms.to_a).to eq([:php])
                end
            end

            context 'false' do
                it 'does not fingerprint the response' do
                    res = nil
                    subject.request( @url + '/fingerprint.php', fingerprint: false ) { |c_res| res = c_res }
                    subject.run

                    expect(res.platforms).to be_empty
                end
            end
        end

        describe ':response_max_size' do
            context 'when not specified' do
                context "and #{Arachni::OptionGroups::HTTP}#response_max_size is specified" do
                    context 'when response bodies are larger that its value' do
                        it 'ignores them' do
                            @opts.http.response_max_size = 0
                            expect(subject.request( @url + '/http_response_max_size',
                                             mode: :sync
                            ).body).to be_empty

                            @opts.http.response_max_size = 1
                            expect(subject.request( @url + '/http_response_max_size',
                                             mode: :sync
                            ).body).to be_empty

                            @opts.http.response_max_size = 999999
                            expect(subject.request( @url + '/http_response_max_size',
                                             mode: :sync
                            ).body).to be_empty
                        end
                    end

                    context 'when response bodies are not larger that its value' do
                        it 'reads them' do
                            @opts.http.response_max_size = 1000000
                            expect(subject.request( @url + '/http_response_max_size',
                                             mode: :sync
                            ).body).not_to be_empty
                        end
                    end
                end
            end

            context 'when specified' do
                context 'when response bodies are larger that its value' do
                    it 'ignores them' do
                        expect(subject.request( @url + '/http_response_max_size',
                                         mode: :sync,
                                         response_max_size: 0
                        ).body).to be_empty

                        expect(subject.request( @url + '/http_response_max_size',
                                         mode: :sync,
                                         response_max_size: 1
                        ).body).to be_empty

                        expect(subject.request( @url + '/http_response_max_size',
                                         mode: :sync,
                                         response_max_size: 999999
                        ).body).to be_empty
                    end
                end

                context 'when response bodies are not larger that its value' do
                    it 'reads them' do
                        expect(subject.request( @url + '/http_response_max_size',
                                         mode: :sync,
                                         response_max_size: 1000000
                        ).body).not_to be_empty
                    end
                end

                context 'when the server returns no Content-Length' do
                    it 'still works' do
                        r = subject.request( @url + '/http_response_max_size/without_content_length',
                                         mode: :sync,
                                         response_max_size: 0
                        )

                        expect(r.headers).not_to include 'Content-Type'
                        expect(r.body).to be_empty

                        r = subject.request( @url + '/http_response_max_size/without_content_length',
                                         mode: :sync,
                                         response_max_size: 1
                        )
                        expect(r.headers).not_to include 'Content-Type'
                        expect(r.body).to be_empty

                        r = subject.request( @url + '/http_response_max_size/without_content_length',
                                         mode: :sync,
                                         response_max_size: 999999
                        )
                        expect(r.headers).not_to include 'Content-Type'
                        expect(r.body).to be_empty

                        r = subject.request( @url + '/http_response_max_size/without_content_length',
                                         mode: :sync,
                                         response_max_size: 1000000
                        )

                        expect(r.headers).not_to include 'Content-Type'
                        expect(r.body).not_to be_empty
                    end
                end
            end

            context 'when < 0' do
                it 'does not enforce a limit' do
                    @opts.http.response_max_size = 0
                    expect(subject.request( @url + '/http_response_max_size',
                                   mode: :sync,
                                   response_max_size: -1
                    ).body).not_to be_empty
                end
            end

            it 'works for asynchronous requests' do
                subject.request( @url + '/http_response_max_size/without_content_length',
                                     mode: :sync,
                                     response_max_size: 0
                ) do |r|
                    expect(r.headers).not_to include 'Content-Type'
                    expect(r.body).to be_empty
                end

                subject.request( @url + '/http_response_max_size/without_content_length',
                                 mode: :sync,
                                 response_max_size: 1
                ) do |r|
                    expect(r.headers).not_to include 'Content-Type'
                    expect(r.body).to be_empty
                end

                subject.request( @url + '/http_response_max_size/without_content_length',
                                 mode: :sync,
                                 response_max_size: 999999
                ) do |r|
                    expect(r.headers).not_to include 'Content-Type'
                    expect(r.body).to be_empty
                end

                subject.request( @url + '/http_response_max_size/without_content_length',
                                 mode: :sync,
                                 response_max_size: 1000000
                ) do |r|
                    expect(r.headers).not_to include 'Content-Type'
                    expect(r.body).not_to be_empty
                end

                subject.run
            end
        end

        describe ':no_cookie_jar' do
            context 'true' do
                it 'skips the cookie-jar' do
                    body = nil
                    subject.request( @url + '/cookies', no_cookie_jar: true ) { |res| body = res.body }
                    subject.run
                    expect(YAML.load( body )).to eq({})
                end
            end
            context 'false' do
                it 'uses the raw data from the cookie jar' do
                    @opts.http.cookie_string = 'my_cookie_name="val1","blah_name"=val2,another_name=another_val'
                    expect(subject.cookie_jar.cookies).to be_empty
                    subject.reset

                    body = nil

                    subject.request( @url + '/cookies', no_cookie_jar: false ) { |res| body = res.body }
                    subject.run
                    expect(YAML.load( body )).to eq({
                        'my_cookie_name' => '"val1"',
                        '"blah_name"' => 'val2',
                        'another_name' => 'another_val'
                    })
                end
                context 'when custom cookies are provided' do
                    it 'merges them with the cookie_jar and override it' do
                        @opts.http.cookie_string = 'my_cookie_name=val1,blah_name=val2,another_name=another_val'
                        expect(subject.cookie_jar.cookies).to be_empty
                        subject.reset

                        body = nil

                        custom_cookies = { 'newcookie' => 'newval', 'blah_name' => 'val3' }
                        subject.request( @url + '/cookies', cookies: custom_cookies,
                                       no_cookie_jar: false ) { |res| body = res.body }
                        subject.run
                        expect(YAML.load( body )).to eq({
                            'my_cookie_name' => 'val1',
                            'blah_name' => 'val3',
                            'another_name' => 'another_val',
                            'newcookie' => 'newval'
                        })
                    end
                end
            end
            context 'nil' do
                it 'defaults to false' do
                    @opts.http.cookie_string = 'my_cookie_name="val1","blah_name"=val2,another_name=another_val'
                    expect(subject.cookie_jar.cookies).to be_empty
                    subject.reset

                    body = nil

                    subject.request( @url + '/cookies', no_cookie_jar: false ) { |res| body = res.body }
                    subject.run
                    expect(YAML.load( body )).to eq({
                        'my_cookie_name' => '"val1"',
                        '"blah_name"' => 'val2',
                        'another_name' => 'another_val'
                    })
                end
            end
        end

        describe ':body' do
            it 'uses its value as a request body' do
                req_body = 'heyaya'
                body = nil
                subject.request( @url + '/body', method: :post, body: req_body ) { |res| body = res.body }
                subject.run
                expect(body).to eq(req_body)
            end
        end

        describe ':method' do
            describe 'nil' do
                it 'performs a GET HTTP request' do
                    body = nil
                    subject.request( @url ) { |res| body = res.body }
                    subject.run
                    expect(body).to eq('GET')
                end
            end
            describe ':get' do
                it 'performs a GET HTTP request' do
                    body = nil
                    subject.request( @url, method: :get ) { |res| body = res.body }
                    subject.run
                    expect(body).to eq('GET')
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
                        expect(YAML.load( body )).to eq params.merge( 'param3' => 'value3' )
                    end
                end
            end
            describe ':post' do
                it 'performs a POST HTTP request' do
                    body = nil
                    subject.request( @url, method: :post ) { |res| body = res.body }
                    subject.run
                    expect(body).to eq('POST')
                end
            end
            describe ':put' do
                it 'performs a PUT HTTP request' do
                    body = nil
                    subject.request( @url, method: :put ) { |res| body = res.body }
                    subject.run
                    expect(body).to eq('PUT')
                end
            end
            describe ':options' do
                it 'performs a OPTIONS HTTP request' do
                    body = nil
                    subject.request( @url, method: :options ) { |res| body = res.body }
                    subject.run
                    expect(body).to eq('OPTIONS')
                end
            end
            describe ':delete' do
                it 'performs a POST HTTP request' do
                    body = nil
                    subject.request( @url, method: :delete ) { |res| body = res.body }
                    subject.run
                    expect(body).to eq('DELETE')
                end
            end
        end

        describe ':parameters' do
            it 'specifies the query params as a hash' do
                body = nil
                params = { 'param' => 'value' }
                subject.request( @url + '/echo', parameters: params ) { |res| body = res.body }
                subject.run
                expect(params).to eq YAML.load( body )
            end

            it 'preserves nullbytes' do
                body = nil
                params = { "pa\0ram" => "v\0alue" }
                subject.request( @url + '/echo', parameters: params ) { |res| body = res.body }
                subject.run
                expect(params).to eq YAML.load( body )
            end
        end

        describe ':body' do
            it 'properly encodes special characters' do
                body = nil
                params = { '% param\ +=&;' => '% value\ +=&;', 'nil' => nil }
                subject.request( @url + '/echo', method: :post, body: params ) { |res| body = res.body }
                subject.run
                expect(YAML.load( body )).to eq({ '% param\ +=&;' => '% value\ +=&;', 'nil' => '' })
            end

            it 'preserves nullbytes' do
                body = nil
                params = { "st\0uff" => "test\0" }
                subject.request( @url + '/echo', method: :post, body: params, ) { |res| body = res.body }
                subject.run
                expect(YAML.load( body )).to eq(params)
            end
        end

        describe ':timeout' do
            describe 'nil' do
                it 'runs without a timeout' do
                    timed_out = false
                    subject.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                    subject.run
                    expect(timed_out).to be_falsey
                end
            end
            describe Numeric do
                it 'sets a timeout value in milliseconds' do
                    timed_out = false
                    subject.request( @url + '/sleep', timeout: 4_000 ) { |res| timed_out = res.timed_out? }
                    subject.run
                    expect(timed_out).to be_truthy

                    timed_out = false
                    subject.request( @url + '/sleep', timeout: 6_000 ) { |res| timed_out = res.timed_out? }
                    subject.run
                    expect(timed_out).to be_falsey
                end
            end
        end

        describe ':username/:password' do
            it 'uses them to authenticate' do
                # first fail to make sure that our test server is actually working properly
                code = 0
                subject.get( @opts.url + 'auth/weird-chars' ) { |res| code = res.code }
                subject.run
                expect(code).to eq(401)

                response = nil
                subject.get(
                    @opts.url + 'auth/weird-chars',
                    username: 'u se rname$@#@#%$3#@%@#',
                    password: 'p a  :wo\'rd$@#@#%$3#@%@#' ) { |res| response = res }
                subject.run
                expect(response.code).to eq(200)
                expect(response.body).to eq('authenticated!')
            end
        end

        describe ':cookies' do
            it 'preserves nullbytess' do
                cookies = { "name\0" => "val\0" }
                body = nil
                subject.request( @url + '/cookies', cookies: cookies ) { |res| body = res.body }
                subject.run
                expect(YAML.load( body )).to eq(cookies)
            end

            describe 'nil' do
                it 'uses te cookies in the CookieJar' do
                    @opts.http.cookie_string = 'my_cookie_name=val1,blah_name=val2,another_name=another_val'
                    expect(subject.cookie_jar.cookies).to be_empty
                    subject.reset

                    body = nil
                    subject.request( @url + '/cookies' ) { |res| body = res.body }
                    subject.run
                    expect(YAML.load( body )).to eq({
                        'my_cookie_name' => 'val1',
                        'blah_name' => 'val2',
                        'another_name' => 'another_val'
                    })
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
                    expect(YAML.load( body )).to eq({ 'key2' => 'val2' })
                end
            end

            describe Hash do
                it 'uses the key-value pairs as cookies' do
                    cookies = { 'name' => 'val' }
                    body = nil
                    subject.request( @url + '/cookies', cookies: cookies ) { |res| body = res.body }
                    subject.run
                    expect(YAML.load( body )).to eq(cookies)
                end

                it 'merges them with the cookie-jar' do
                    @opts.http.cookie_string = 'my_cookie_name=val1,blah_name=val2,another_name=another_val'
                    expect(subject.cookie_jar.cookies).to be_empty
                    subject.reset

                    body = nil
                    subject.request(
                        @url + '/cookies',
                        cookies: {
                            'my_cookie_name' => 'updated_val'
                        }
                    ) { |res| body = res.body }
                    subject.run

                    expect(YAML.load( body )).to eq({
                        'my_cookie_name' => 'updated_val',
                        'blah_name' => 'val2',
                        'another_name' => 'another_val'
                    })
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

                        expect(YAML.load( body )).to eq({ 'test' => '1', 'name' => 'val' })
                    end
                end
            end
        end

        describe ':mode' do
            describe 'nil' do
                it 'performs the request asynchronously' do
                    performed = false
                    subject.request( @url ) { performed = true }
                    subject.run
                    expect(performed).to be_truthy
                end
            end
            describe ':async' do
                it 'performs the request asynchronously' do
                    performed = false
                    subject.request( @url, mode: :sync ) { performed = true }
                    subject.run
                    expect(performed).to be_truthy
                end
            end
            describe ':sync' do
                it 'performs the request synchronously and returns the response' do
                    expect(subject.request( @url, mode: :sync )).to be_kind_of Arachni::HTTP::Response
                end

                it 'assigns a #request to the returned response' do
                    expect(subject.request( @url, mode: :sync ).request).to be_kind_of Arachni::HTTP::Request
                end

                context 'when a block is given' do
                    it 'passes the response to it as well' do
                        called = []
                        response = subject.request( @url, mode: :sync ) do |r|
                            called << r
                        end

                        expect(response).to be_kind_of Arachni::HTTP::Response
                        expect(called).to eq([response])
                    end
                end
            end
        end

        describe ':headers' do
            describe 'nil' do
                it 'uses the default headers' do
                    body = nil
                    subject.request( @url + '/headers' ) { |res| body = res.body }
                    subject.run
                    sent_headers = YAML.load( body )
                    subject.headers.each { |k, v| expect(sent_headers[k]).to eq(v) }
                end
            end

            describe Hash do
                it 'merges them with the default headers' do
                    headers = { 'My-Header' => 'my value'}
                    body = nil
                    subject.request( @url + '/headers', headers: headers ) { |res| body = res.body }
                    subject.run
                    sent_headers = YAML.load( body )
                    subject.headers.merge( headers ).each { |k, v| expect(sent_headers[k]).to eq(v) }
                end
            end
        end

        describe ':update_cookies' do
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
                    expect(subject.cookies).to eq(cookies)
                end
            end

            describe 'false' do
                it 'skips the cookie_jar' do
                    cookies = []
                    cookies << Arachni::Element::Cookie.new(
                        url: @url,
                        inputs: { 'key2' => 'val2' }
                    )
                    subject.update_cookies( cookies )
                    subject.request( @url + '/update_cookies', update_cookies: false )
                    subject.run
                    expect(subject.cookies).to eq(cookies)
                end
            end

            describe 'true' do
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

                    cookie = subject.cookies.find { |c| c.value == 'val2 [UPDATED!]'}
                    expect(cookie).to be_truthy
                end
            end
        end

        describe ':follow_location' do
            describe 'nil' do
                it 'ignores redirects' do
                    res = nil
                    subject.request( @url + '/follow_location' ) { |c_res| res = c_res }
                    subject.run
                    expect(res.url.start_with?( @url + '/follow_location' )).to be_truthy
                    expect(res.body).to eq('')
                end
            end
            describe 'false' do
                it 'ignores redirects' do
                    res = nil
                    subject.request( @url + '/follow_location', follow_location: false ) { |c_res| res = c_res }
                    subject.run
                    expect(res.url.start_with?( @url + '/follow_location' )).to be_truthy
                    expect(res.body).to eq('')
                end
            end
            describe 'true' do
                it 'follows redirects' do
                    res = nil
                    subject.request( @url + '/follow_location', follow_location: true ) { |c_res| res = c_res }
                    subject.run
                    expect(res.url).to eq(@url + '/redir_2')
                    expect(res.body).to eq("Welcome to redir_2!")
                end
            end
        end

        context 'when cookie-jar lookup fails' do
            it 'only uses the given cookies' do
                @opts.http.cookie_string = 'my_cookie_name=val1,blah_name=val2,another_name=another_val'
                expect(subject.cookie_jar.cookies).to be_empty
                subject.reset
                expect(subject.cookie_jar.cookies).to be_any

                allow(subject.cookie_jar).to receive(:for_url) { raise }

                body = nil
                subject.request(
                    @url + '/cookies',
                    cookies: { 'blah' => 'val' }
                ) { |res| body = res.body }
                subject.run

                expect(YAML.load( body )).to eq({ 'blah' => 'val' })
            end
        end
    end

    describe '#get' do
        it 'queues a GET request' do
            body = nil
            subject.get { |res| body = res.body }
            subject.run
            expect(body).to eq('GET')
        end
    end

    describe '#trace' do
        it 'queues a TRACE request' do
            expect(subject.trace.method).to eq(:trace)
        end
    end

    describe '#post' do
        it 'queues a POST request' do
            body = nil
            subject.post { |res| body = res.body }
            subject.run
            expect(body).to eq('POST')
        end

        it 'passes :parameters as a #request :body' do
            body = nil
            params = { '% param\ +=&;' => '% value\ +=&;', 'nil' => nil }
            subject.post( @url + '/echo', parameters: params ) { |res| body = res.body }
            subject.run
            expect(YAML.load( body )).to eq({ '% param\ +=&;' => '% value\ +=&;', 'nil' => '' })
        end
    end

    describe '#cookie' do
        it 'queues a GET request' do
            body = nil
            cookies = { 'name' => "v%+;al\00=" }
            subject.cookie( @url + '/cookies', parameters: cookies ) { |res| body = res.body }
            subject.run
            expect(YAML.load( body )).to eq(cookies)
        end
    end

    describe '#header' do
        it 'queues a GET request' do
            body = nil
            headers = { 'name' => 'val' }
            subject.header( @url + '/headers', parameters: headers ) { |res| body = res.body }
            subject.run
            expect(YAML.load( body )['Name']).to eq(headers.values.first)
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

            expect(r).to be_kind_of Arachni::HTTP::Response
        end
    end

    describe '#update_cookies' do
        it 'updates the cookies' do
            cookies = []
            cookies << Arachni::Element::Cookie.new(
                url: @url,
                inputs: { 'key2' => 'val2' }
            )

            expect(subject.cookies).to be_empty
            subject.update_cookies( cookies )
            expect(subject.cookies).to eq(cookies)
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

            expect(callback_cookies).to eq(cookies)
            expect(callback_response).to eq(res)
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

            expect(@opts.http.cookies).to be_empty
            expect(subject.cookies).to be_empty
            subject.parse_and_set_cookies( res )
            expect(subject.cookies).to eq(cookies)
        end
    end

    describe '.info' do
        it 'returns a hash with an output name' do
            expect(described_class.info[:name]).to eq('HTTP')
        end
    end

end
