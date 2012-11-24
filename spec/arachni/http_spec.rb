require_relative '../spec_helper'

describe Arachni::HTTP do

    before( :all ) do
        @opts = Arachni::Options.instance
        @http = Arachni::HTTP
        @url = server_url_for( :http )
    end
    before( :each ){
        @opts.reset
        @opts.audit_links = true
        @opts.url  = @url
        @http.reset
    }

    it 'should support gzip content-encoding' do
        body = nil
        @http.get( @opts.url + 'gzip' ) { |res| body = res.body }
        @http.run
        body.should == 'success'
    end

    it 'should preserve set-cookies' do
        body = nil
        @http.get( @opts.url + 'set_and_preserve_cookies', update_cookies: true )
        @http.run
        @http.cookies.first.value.should == "=stuf \00 here=="
        @http.get( @opts.url + 'cookies' ) { |res| body = res.body }
        @http.run
        body.should == "stuff==stuf \00 here=="
    end

    describe 'Arachni::Options#http_req_limit' do
        context Integer do
            it 'should use it as a max_concurrency' do
                @opts.http_req_limit = 34
                @http.reset
                @http.max_concurrency.should == 34
            end
        end
        context 'nil' do
            it 'should use a default max concurrency setting' do
                @opts.http_req_limit = nil
                @http.reset
                @http.max_concurrency.should == Arachni::HTTP::MAX_CONCURRENCY
            end
        end
    end

    describe 'Arachni::Options#http_timeout' do
        context Integer do
            it 'should use it as an HTTP timeout' do
                @opts.http_timeout = 10000000000
                timed_out = false
                @http.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                @http.run
                timed_out.should be_false

                @opts.http_timeout = 1
                @http.reset
                timed_out = false
                @http.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                @http.run
                timed_out.should be_true
            end
        end
        context 'nil' do
            it 'should use a default timeout setting' do
                timed_out = false
                @http.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                @http.run
                timed_out.should be_false
            end
        end
    end


    describe 'Arachni::Options#url' do
        context 'when the target URL includes auth credentials' do
            it 'should use them globally' do
                url = Arachni::Module::Utilities.uri_parse( server_url_for( :http_auth ) )
                @opts.url = url.to_s

                # first fail to make sure that our test server is actually working properly
                code = 0
                @http.get( @opts.url + 'auth' ) { |res| code = res.code }
                @http.run
                code.should == 401

                # now test the client
                url.user = 'username'
                url.password = 'password'
                @opts.url = url.to_s

                body = nil
                @http.get( @opts.url + 'auth' ) { |res| body = res.body }
                @http.run
                body.should == 'authenticated!'
            end
        end
    end

    describe 'Arachni::Options#user_agent' do
        context String do
            it 'should use it as a user agent' do
                ua = 'my user agent'
                @opts.user_agent = ua.dup
                @http.reset

                body = nil
                @http.get( @opts.url + 'user-agent' ) { |res| body = res.body }
                @http.run
                body.should == ua
            end
        end
        context 'nil' do
            it 'should use a default user agent setting and update the global setting' do
                @opts.user_agent = nil
                @http.reset

                body = nil
                @http.get( @opts.url + 'user-agent' ) { |res| body = res.body }
                @http.run
                body.should == Arachni::HTTP::USER_AGENT + Arachni::VERSION.to_s
                @opts.user_agent.should == body
            end
        end
    end

    describe 'Arachni::Options#redirect_limit' do
        context Integer do
            it 'should not exceed that amount of redirects' do
                @opts.redirect_limit = 2
                @http.reset

                code = nil
                @http.get( @opts.url + 'redirect', follow_location: true ) { |res| code = res.code }
                @http.run
                code.should == 302

                @opts.redirect_limit = 10
                @http.reset

                body = nil
                @http.get( @opts.url + 'redirect', follow_location: true ) { |res| body = res.body }
                @http.run
                body.should == 'This is the end.'
            end
        end
        context 'nil' do
            it 'should use a default setting and update the global setting' do
                @opts.redirect_limit = nil
                @http.reset

                body = nil
                @http.get( @opts.url + 'redirect', follow_location: true ) { |res| body = res.body }
                @http.run
                body.should == 'This is the end.'

                @opts.redirect_limit.should == Arachni::HTTP::REDIRECT_LIMIT
            end
        end
    end

    describe '#sandbox' do
        it 'should preserve state, run the block and then restore it' do

            @http.cookies.should be_empty
            body = nil
            @http.get( @opts.url + 'set_and_preserve_cookies', update_cookies: true )
            @http.run
            @http.cookies.should be_any

            headers = @http.headers.dup

            signals = []
            @http.add_on_complete do |r|
                signals << :out
            end

            @http.get( @opts.url + 'out', async: false )
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

                @http.get( @opts.url + 'in', async: false )
                @http.run
            end
            @http.get( @opts.url + 'out', async: false )

            signals.delete( :out )
            signals.size.should == 1

            @http.headers.include?( 'X-Custom' ).should be_false
            @http.cookies.should be_any
        end
    end

    describe '#url' do
        it 'should return the URL in opts' do
            @http.url.should == @opts.url.to_s
        end
    end

    describe '#page=' do
        it 'should update the trainer and the cookiejar using the given page' do
            cookies = []
            cookies << Arachni::Element::Cookie.new( 'http://test.com',
                                                     'key1' => 'val1' )
            cookies << Arachni::Element::Cookie.new( @url,
                                                     'key2' => 'val2' )

            page = Arachni::Page.new( cookiejar: cookies )
            @http.page = page
            @http.cookies.should == cookies
            @http.trainer.page.should == page
        end
    end

    describe '#headers' do
        it 'should provide access to default headers' do
            headers = @http.headers
            headers['Accept'].should == 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
            headers['User-Agent'].should == 'Arachni/v' + Arachni::VERSION
        end

        context 'when provided with custom headers' do
            it 'should include them' do
                @opts.custom_headers = {
                    'User-Agent' => 'My UA',
                    'From'       => 'Some dude',
                }
                @http.reset
                headers = @http.headers
                headers['From'].should == @opts.custom_headers['From']
                headers['Accept'].should == 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
                headers['User-Agent'].should == @opts.custom_headers['User-Agent']
            end
        end

        context 'when the authed_by option is set' do
            it 'should include it in the From field' do
                @opts.authed_by = 'The Dude'
                @http.reset
                @http.headers['From'].should == @opts.authed_by
            end
        end

    end

    describe '#cookie_jar' do
        it 'should provide access to the Cookie-jar' do
            @http.cookie_jar.is_a?( Arachni::HTTP::CookieJar ).should be_true
        end

        context 'when the cookie_jar option is set' do
            it 'should add the contained cookies to the CookieJar' do
                @opts.cookie_jar = spec_path + '/fixtures/cookies.txt'
                @http.cookie_jar.cookies.should be_empty
                @http.reset
                cookies = @http.cookie_jar.cookies
                cookies.size.should == 4
                cookies.should == Arachni::Module::Utilities.cookies_from_file( '', @opts.cookie_jar )
            end
            context 'but the path is invalid' do
                it 'should raise an exception' do
                    @opts.cookie_jar = spec_path + '/fixtures/cookies.does_not_exist.txt'
                    raised = false
                    begin
                        @http.reset
                    rescue Arachni::Exceptions::NoCookieJar
                        raised = true
                    end
                    raised.should be_true
                end
            end
        end

        context 'when the cookies option is set' do
            it 'should add those cookies to the CookieJar' do
                cookie_jar_file = spec_path + '/fixtures/cookies.txt'
                @opts.cookies = Arachni::Module::Utilities.cookies_from_file( '', cookie_jar_file )
                @http.cookie_jar.cookies.should be_empty
                @http.reset
                cookies = @http.cookie_jar.cookies
                cookies.size.should == 4
                cookies.should == @opts.cookies
            end
        end

        context 'when the cookie_string option is set' do
            it 'should parse the string and add those cookies to the CookieJar' do
                @opts.cookie_string = 'my_cookie_name=val1;blah_name=val2; stuff=%25blah; another_name=another_val'
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
        it 'should return the current cookies' do
            @opts.cookie_string = 'my_cookie_name=val1;blah_name=val2; another_name=another_val'
            @http.cookie_jar.cookies.should be_empty
            @http.reset
            @http.cookies.size.should == 3
            @http.cookies.should == @http.cookie_jar.cookies
        end
    end

    describe '#run' do
        it 'should perform the queues requests' do
            @http.run
        end

        it 'should call the after_run callbacks ONCE' do
            called = false
            @http.after_run { called = true }
            @http.run
            called.should be_true
            called = false
            @http.run
            called.should be_false
        end

        it 'should call the after_run_persistent callbacks EVERY TIME' do
            called = false
            @http.after_run_persistent { called = true }
            @http.run
            called.should be_true
            called = false
            @http.run
            called.should be_true
        end

        it 'should calculate the burst average response time' do
            @http.run
            @http.burst_runtime.should > 0
        end

        it 'should update curr_res_time, curr_res_cnt, average_res_time and curr_res_per_second' +
               ' during runtime but reset them afterwards' do
            @http.curr_res_time.should == 0
            @http.curr_res_cnt.should == 0
            @http.average_res_time.should == 0
            @http.curr_res_per_second.should == 0

            curr_res_cnt = 0
            curr_res_time = 0
            average_res_time = 0
            curr_res_per_second = 0
            20.times{
                @http.get {
                    curr_res_time = @http.curr_res_time
                    curr_res_cnt = @http.curr_res_cnt
                    average_res_time = @http.average_res_time
                    curr_res_per_second = @http.curr_res_per_second
                }
            }
            @http.run
            curr_res_time.should > 0
            curr_res_cnt.should > 0
            average_res_time.should > 0
            curr_res_per_second.should > 0
            @http.curr_res_time.should == 0
            @http.curr_res_cnt.should == 0
        end
    end

    describe '#abort' do
        it 'should abort the running requests on a best effort basis' do
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
        it 'should default to 20' do
            @http.max_concurrency.should == 20
        end
        it 'should respect the http_req_limit option' do
            @opts.http_req_limit = 50
            @http.reset
            @http.max_concurrency.should == 50
        end
    end

    describe '#max_concurrency=' do
        it 'should set the max_concurrency setting' do
            @http.max_concurrency.should_not == 30
            @http.max_concurrency = 30
            @http.max_concurrency.should == 30
        end
    end

    describe '#request' do
        it 'should use the URL in Arachni::Options.instance.url as a default' do
            url = nil
            @http.request{ |res| url = res.effective_url }
            @http.run
            url.start_with?( @opts.url.to_s ).should be_true
        end
        it 'should raise exception when no URL is available' do
            @opts.reset
            @http.reset
            raised = false
            begin
                @http.request
            rescue
                raised = true
            end
            raised.should be_true
        end

        describe :no_cookiejar do
            context true do
                it 'should not use the cookiejar' do
                    body = nil
                    @http.request( @url + '/cookies', no_cookiejar: true ) { |res| body = res.body }
                    @http.run
                    body.should == ''
                end
            end
            context false do
                it 'should use the cookiejar' do
                    @opts.cookie_string = 'my_cookie_name=val1;blah_name=val2;another_name=another_val'
                    @http.cookie_jar.cookies.should be_empty
                    @http.reset

                    body = nil

                    @http.request( @url + '/cookies', no_cookiejar: false ) { |res| body = res.body }
                    @http.run
                    body.should == @opts.cookie_string
                end
                context 'when custom cookies are provided' do
                    it 'should merge them with the cookiejar and override it' do
                        @opts.cookie_string = 'my_cookie_name=val1;blah_name=val2;another_name=another_val'
                        @http.cookie_jar.cookies.should be_empty
                        @http.reset

                        body = nil

                        custom_cookies = { 'newcookie' => 'newval', 'blah_name' => 'val3' }
                        @http.request( @url + '/cookies', cookies: custom_cookies,
                                       no_cookiejar: false ) { |res| body = res.body }
                        @http.run
                        body.should == 'my_cookie_name=val1;blah_name=val3;another_name=another_val;newcookie=newval'
                    end
                end
            end
            context 'nil' do
                it 'should default to false' do
                    @opts.cookie_string = 'my_cookie_name=val1;blah_name=val2;another_name=another_val'
                    @http.cookie_jar.cookies.should be_empty
                    @http.reset

                    body = nil

                    @http.request( @url + '/cookies' ) { |res| body = res.body }
                    @http.run
                    body.should == @opts.cookie_string
                end
            end
        end

        describe :body do
            it 'should use its value as a request body' do
                req_body = 'heyaya'
                body = nil
                @http.request( @url + '/body', method: :post, body: req_body ) { |res| body = res.body }
                @http.run
                body.should == req_body
            end
        end

        describe :method do
            describe 'nil' do
                it 'should perform a GET HTTP request' do
                    body = nil
                    @http.request( @url ) { |res| body = res.body }
                    @http.run
                    body.should == 'GET'
                end
            end
            describe :get do
                it 'should perform a GET HTTP request' do
                    body = nil
                    @http.request( @url, method: :get ) { |res| body = res.body }
                    @http.run
                    body.should == 'GET'
                end

                context 'when there are both query string and hash params' do
                    it 'should merge them while giving priority to the hash params' do
                        body = nil
                        params = {
                            'param1' => 'value1_updated',
                            'param2' => 'value 2'
                        }
                        url = @url + '/echo?param1=value1&param3=value3'
                        @http.request( url,
                            remove_id: true, params: params, method: :get
                        ){ |res| body = res.body }
                        @http.run
                        body.should == params.merge( 'param3' => 'value3' ).to_s
                    end
                end
            end
            describe :post do
                it 'should perform a POST HTTP request' do
                    body = nil
                    @http.request( @url, method: :post ) { |res| body = res.body }
                    @http.run
                    body.should == 'POST'
                end
            end
            describe :put do
                it 'should perform a PUT HTTP request' do
                    body = nil
                    @http.request( @url, method: :put ) { |res| body = res.body }
                    @http.run
                    body.should == 'PUT'
                end
            end
            describe :options do
                it 'should perform a OPTIONS HTTP request' do
                    body = nil
                    @http.request( @url, method: :options ) { |res| body = res.body }
                    @http.run
                    body.should == 'OPTIONS'
                end
            end
            describe :delete do
                it 'should perform a POST HTTP request' do
                    body = nil
                    @http.request( @url, method: :delete ) { |res| body = res.body }
                    @http.run
                    body.should == 'DELETE'
                end
            end
        end
        describe :params do
            it 'should specify the query params as a hash' do
                body = nil
                params = { 'param' => 'value' }
                @http.request( @url + '/echo',
                    params: params,
                    remove_id: true
                ) { |res| body = res.body }
                @http.run
                params.to_s.should == body
            end
            context 'POST' do
                it 'should encode special characters' do
                    body = nil
                    params = { '% param\ +=&;' => '% value\ +=&;', 'nil' => nil }
                    @http.request( @url + '/echo',
                                   method: :post,
                                   params: params,
                                   remove_id: true
                    ) { |res| body = res.body }
                    @http.run
                    body.should == { '% param\ +=&;' => '% value\ +=&;' }.to_s
                end
            end

        end
        #describe :remove_id do
        #    describe 'nil' do
        #        it 'should include the framework-wide hash ID in the params' do
        #            body = nil
        #            @http.request( @url + '/echo' ) { |res| body = res.body }
        #            @http.run
        #            body.should == { Arachni::Module::Utilities.seed => '' }.to_s
        #        end
        #    end
        #    describe false do
        #        it 'should include the framework-wide hash ID in the params' do
        #            body = nil
        #            @http.request( @url + '/echo', remove_id: false ) { |res| body = res.body }
        #            @http.run
        #            body.should == { Arachni::Module::Utilities.seed => '' }.to_s
        #        end
        #    end
        #    describe true do
        #        it 'should remove the framework-wide hash ID from the params' do
        #            body = nil
        #            @http.request( @url + '/echo', remove_id: true ) { |res| body = res.body }
        #            @http.run
        #            body.should == {}.to_s
        #        end
        #    end
        #end

        describe :train do
            before( :all ) do
                res = @http.get( @url, async: false, remove_id: true ).response
                @page = Arachni::Page.from_response( res, @opts )
            end
            describe 'nil' do
                it 'should not pass the response to the Trainer' do
                    @http.trainer.init( @page )
                    @http.request( @url + '/elems' )
                    @http.run
                    @http.trainer.flush.should be_empty
                end
            end
            describe false do
                it 'should not pass the response to the Trainer' do
                    @http.trainer.init( @page )
                    @http.request( @url + '/elems', train: false )
                    @http.run
                    @http.trainer.flush.should be_empty
                end
            end
            describe true do
                it 'should pass the response to the Trainer' do
                    @http.trainer.init( @page )
                    @http.request( @url + '/elems', train: true )
                    @http.run
                    @http.trainer.flush.should be_any
                end

                context 'when a redirection leads to new elements' do
                    it 'should pass the response to the Trainer' do
                        @http.trainer.init( @page )
                        @http.request( @url + '/train/redirect', train: true )
                        @http.run
                        page = @http.trainer.flush.first
                        page.links.first.auditable.include?( 'msg' ).should be_true
                    end
                end
            end
        end

        describe :timeout do
            describe 'nil' do
                it 'should not set a timeout value' do
                    timed_out = false
                    @http.request( @url + '/sleep' ) { |res| timed_out = res.timed_out? }
                    @http.run
                    timed_out.should be_false
                end
            end
            describe Numeric do
                it 'should not set a timeout value' do
                    timed_out = false
                    @http.request( @url + '/sleep', timeout: 1.3 ) { |res| timed_out = res.timed_out? }
                    @http.run
                    timed_out.should be_true
                end
            end
        end

        describe :cookies do
            describe 'nil' do
                it 'should use te cookies in the CookieJar' do
                    @opts.cookie_string = 'my_cookie_name=val1;blah_name=val2;another_name=another_val'
                    @http.cookie_jar.cookies.should be_empty
                    @http.reset

                    body = nil
                    @http.request( @url + '/cookies' ) { |res| body = res.body }
                    @http.run
                    body.should == @opts.cookie_string
                end

                it 'should only send the appropriate cookies for the domain' do
                    cookies = []
                    cookies << Arachni::Element::Cookie.new( 'http://test.com',
                        'key1' => 'val1' )
                    cookies << Arachni::Element::Cookie.new( @url,
                        'key2' => 'val2' )

                    @http.cookie_jar.update( cookies )
                    body = nil
                    @http.request( @url + '/cookies' ) { |res| body = res.body }
                    @http.run
                    body.should == 'key2=val2'
                end
            end
            describe Hash do
                it 'should use the key-value pairs as cookies' do
                    cookies = { 'name' => 'val' }
                    body = nil
                    @http.request( @url + '/cookies', cookies: cookies ) { |res| body = res.body }
                    @http.run
                    body.should == cookies.keys.first.to_s  + '=' + cookies.values.first.to_s
                end
            end
        end

        describe :async do
            describe 'nil' do
                it 'should perform the request asynchronously' do
                    performed = false
                    @http.request( @url ) { performed = true }
                    @http.run
                    performed.should be_true
                end
            end
            describe true do
                it 'should perform the request asynchronously' do
                    performed = false
                    @http.request( @url, async: true ) { performed = true }
                    @http.run
                    performed.should be_true
                end
            end
            describe false do
                it 'should not perform the request asynchronously' do
                    performed = false
                    @http.request( @url, async: false ) { performed = true }
                    performed.should be_true
                end
            end
        end

        describe :headers do
            describe 'nil' do
                it 'should use the default headers' do
                    body = nil
                    @http.request( @url + '/headers' ) { |res| body = res.body }
                    @http.run
                    sent_headers = YAML.load( body )
                    @http.headers.each { |k, v| sent_headers[k].should == v }
                end
            end

            describe Hash do
                it 'should merge them with the default headers' do
                    headers = { 'My-Header' => 'my value'}
                    body = nil
                    @http.request( @url + '/headers', headers: headers ) { |res| body = res.body }
                    @http.run
                    header_str = @http.headers.merge( headers ).
                        map { |k, v| k + '=' + v }.join( ';' )
                    sent_headers = YAML.load( body )
                    @http.headers.merge( headers ).each { |k, v| sent_headers[k].should == v }
                end
            end
        end

        describe :update_cookies do
            describe 'nil' do
                it 'should not update the cookiejar' do
                    cookies = []
                    cookies << Arachni::Element::Cookie.new( @url,
                        'key2' => 'val2' )
                    @http.update_cookies( cookies )
                    body = nil
                    @http.request( @url + '/update_cookies' ) { |res| body = res.body }
                    @http.run
                    @http.cookies.should == cookies
                end
            end

            describe false do
                it 'should not update the cookiejar' do
                    cookies = []
                    cookies << Arachni::Element::Cookie.new( @url,
                        'key2' => 'val2' )
                    @http.update_cookies( cookies )
                    body = nil
                    @http.request( @url + '/update_cookies', update_cookies: false ) { |res| body = res.body }
                    @http.run
                    @http.cookies.should == cookies
                end
            end

            describe true do
                it 'should update the cookiejar' do
                    cookies = []
                    cookies << Arachni::Element::Cookie.new( @url,
                        'key2' => 'val2' )
                    @http.update_cookies( cookies )
                    body = nil
                    @http.request( @url + '/update_cookies', update_cookies: true ) { |res| body = res.body }
                    @http.run
                    @http.cookies.first.value.should == cookies.first.value + ' [UPDATED!]'
                end
            end
        end

        describe :follow_location do
            describe 'nil' do
                it 'should not follow redirects' do
                    res = nil
                    @http.request( @url + '/follow_location' ) { |c_res| res = c_res }
                    @http.run
                    res.effective_url.start_with?( @url + '/follow_location' ).should be_true
                    res.body.should == ''
                end
            end
            describe false do
                it 'should not follow redirects' do
                    res = nil
                    @http.request( @url + '/follow_location', follow_location: false ) { |c_res| res = c_res }
                    @http.run
                    res.effective_url.start_with?( @url + '/follow_location' ).should be_true
                    res.body.should == ''
                end
            end
            describe true do
                it 'should follow redirects' do
                    res = nil
                    @http.request( @url + '/follow_location', follow_location: true ) { |c_res| res = c_res }
                    @http.run
                    res.effective_url.should == @url + '/redir_2'
                    res.body.should == "Welcome to redir_2!"
                end
            end
        end
    end

    describe '#get' do
        it 'should perform a GET request' do
            body = nil
            @http.get { |res| body = res.body }
            @http.run
            body.should == 'GET'
        end
    end

    describe '#post' do
        it 'should perform a GET request' do
            body = nil
            @http.post { |res| body = res.body }
            @http.run
            body.should == 'POST'
        end
    end

    describe '#cookie' do
        it 'should perform a GET request' do
            body = nil
            cookies = { 'name' => "v%+;al\00=" }
            @http.cookie( @url + '/cookies', params: cookies ) { |res| body = res.body }
            @http.run
            body.should == cookies.keys.first + '=' + cookies.values.first
        end
    end

    describe '#headers' do
        it 'should perform a GET request' do
            body = nil
            headers = { 'name' => 'val' }
            @http.header( @url + '/headers', params: headers ) { |res| body = res.body }
            @http.run
            YAML.load( body )['Name'].should == headers.values.first
        end
    end

    describe '#update_cookies' do
        it 'should update the cookies' do
            cookies = []
            cookies << Arachni::Element::Cookie.new( @url,
                'key2' => 'val2' )
            @http.cookies.should be_empty
            @http.update_cookies( cookies )
            @http.cookies.should == cookies
        end
    end

    describe '#on_new_cookies' do
        it 'should add blocks to be called when new cookies arrive' do
            cookies = []
            cookies << Arachni::Element::Cookie.new( @url,
                'name' => 'value' )
            res = Typhoeus::Response.new( effective_url: @url, headers_hash: { 'Set-Cookie' => 'name=value' } )

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
        it 'should update the cookies from a response and call on_new_cookies blocks' do
            cookies = []
            cookies << Arachni::Element::Cookie.new( @url,
                'name' => 'value' )
            res = Typhoeus::Response.new( effective_url: @url, headers_hash: { 'Set-Cookie' => 'name=value' } )

            @opts.cookies.should be_nil
            @http.cookies.should be_empty
            @http.parse_and_set_cookies( res )
            @http.cookies.should == cookies
            @opts.cookies.should == cookies
        end
    end


    describe '#custom_404?' do
        before { @custom_404 = @url + '/custom_404/' }

        context 'when not dealing with a custom 404 handler' do
            it 'should not identify the responses as custom 404s' do
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
            it 'should identify custom 404 (Not Found) responses' do
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
            context 'which includes the required resource in the response' do
                it 'should identify custom 404 (Not Found) responses' do
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
                it 'should identify custom 404 (Not Found) responses' do
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
                it 'should identify custom 404 (Not Found) responses' do
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
