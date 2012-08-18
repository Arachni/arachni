=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require 'typhoeus'
require 'singleton'

module Arachni
require Options.instance.dir['lib'] + 'typhoeus/utils'
require Options.instance.dir['lib'] + 'typhoeus/hydra'
require Options.instance.dir['lib'] + 'typhoeus/request'
require Options.instance.dir['lib'] + 'typhoeus/response'
require Options.instance.dir['lib'] + 'utilities'
require Options.instance.dir['lib'] + 'module/trainer'
require Options.instance.dir['lib'] + 'mixins/observable'
require Options.instance.dir['lib'] + 'http/cookie_jar'

#
# Provides a system-wide, simple and high-performance HTTP interface.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class HTTP
    include Singleton
    include Arachni::Module::Output
    include Arachni::Utilities
    include Arachni::Mixins::Observable

    # Default maximum concurrency for HTTP requests.
    MAX_CONCURRENCY = 20

    # Default maximum redirect limit.
    REDIRECT_LIMIT  = 20

    # Default user agent (will be appended the current Arachni version).
    USER_AGENT      = 'Arachni/v'

    # Don't let the request queue grow more than this amount, if it does then
    # run the queued requests to unload it
    MAX_QUEUE_SIZE  = 5000

    # @return   [String]    framework seed/target URL
    attr_reader :url

    # @return    [Hash]     default headers for each request
    attr_reader :headers

    # @return    [CookieJar]
    attr_reader :cookie_jar

    # @return   [Integer]   amount of performed requests
    attr_reader :request_count

    # @return   [Integer]   amount of received responses
    attr_reader :response_count

    # @return   [Integer]   amount of timed-out requests
    attr_reader :time_out_count

    # @return   [Integer]   sum of the response times of the running requests (of the current burst)
    attr_reader :curr_res_time

    # @return   [Integer]   amount of responses received for the running requests (of the current burst)
    attr_reader :curr_res_cnt

    # @return   [Arachni::Module::Trainer]
    attr_reader :trainer

    def initialize
        reset
    end

    #
    # Re-initializes the singleton
    #
    # @return   [Arachni::HTTP] self
    #
    def reset
        opts = Options.instance

        req_limit = opts.http_req_limit || 20

        hydra_opts = {
            max_concurrency: req_limit,
            method:          :auto
        }

        if opts.url
            parsed_url = uri_parse( opts.url )
            hydra_opts.merge!(
                username: parsed_url.user,
                password: parsed_url.password
            )
        end

        @url = opts.url.to_s
        @url = nil if @url.empty?

        @hydra      = Typhoeus::Hydra.new( hydra_opts )
        @hydra_sync = Typhoeus::Hydra.new( hydra_opts.merge( max_concurrency: 1 ) )

        @hydra.disable_memoization
        @hydra_sync.disable_memoization

        @trainer = Arachni::Module::Trainer.new( opts )

        opts.user_agent ||= USER_AGENT + Arachni::VERSION.to_s
        @headers = {
            'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'User-Agent'    => opts.user_agent
        }
        @headers['From'] = opts.authed_by if opts.authed_by

        @headers.merge!( opts.custom_headers )

        @cookie_jar = CookieJar.new( opts.cookie_jar )
        update_cookies( opts.cookies ) if opts.cookies

        if opts.cookie_string
            cookies = opts.cookie_string.split( ';' ).map do |cookie_pair|
                k, v = *cookie_pair.split( '=', 2 )
                Arachni::Parser::Element::Cookie.new( opts.url.to_s, k.strip => v.strip )
            end.flatten.compact
            update_cookies( cookies )
        end

        proxy_opts = {}
        proxy_opts = {
            proxy:          "#{opts.proxy_host}:#{opts.proxy_port}",
            proxy_username: opts.proxy_username,
            proxy_password: opts.proxy_password,
            proxy_type:     opts.proxy_type
        } if opts.proxy_host

        opts.redirect_limit ||= REDIRECT_LIMIT
        @opts = {
            follow_location:               false,
            max_redirects:                 opts.redirect_limit,
            disable_ssl_peer_verification: true,
            timeout:                       50000
        }.merge( proxy_opts )

        @request_count  = 0
        @response_count = 0
        @time_out_count = 0

        # we'll use it to identify our requests
        @rand_seed = seed( )

        @curr_res_time = 0
        @curr_res_cnt  = 0
        @burst_runtime = 0

        @queue_size = 0

        @after_run = []
        self
    end

    #
    # Runs Hydra (all the asynchronous queued HTTP requests)
    #
    # Should only be called by the framework
    # after all module threads have been joined!
    #
    def run
        exception_jail {
            @burst_runtime = nil
            hydra_run

            @after_run.each { |block| block.call }
            @after_run.clear

            call_after_run_persistent

            @curr_res_time = 0
            @curr_res_cnt  = 0
        }
    end

    # Aborts the running requests on a best effort basis
    def abort
        exception_jail { @hydra.abort }
    end

    # @return   [Integer]   amount of time (in seconds) that the current burst has been running
    def burst_runtime
        @burst_runtime.to_i > 0 ? @burst_runtime : Time.now - (@burst_runtime_start || Time.now)
    end

    # @return   [Integer]   average response time for the running requests (i.e. the current burst)
    def average_res_time
        return 0 if @curr_res_cnt == 0
        @curr_res_time / @curr_res_cnt
    end

    # @return   [Integer]   responses/second for the running requests (i.e. the current burst)
    def curr_res_per_second
        if @curr_res_cnt > 0 && burst_runtime > 0
            return (@curr_res_cnt / burst_runtime).to_i
        end
        0
    end

    #
    # Sets the maximum concurrency of HTTP requests
    #
    # @param   [Integer]   concurrency
    #
    def max_concurrency=( concurrency )
        @hydra.max_concurrency = concurrency
    end

    # @return   [Integer]   current maximum concurrency of HTTP requests
    def max_concurrency
        @hydra.max_concurrency
    end

    # @return   [Array<Arachni::Parser::Element::Cookie>]   all cookies in the jar
    def cookies
        @cookie_jar.cookies
    end

    #
    # Gets called each time a hydra run finishes.
    #
    # @return   [Arachni::HTTP] self
    #
    def after_run( &block )
        @after_run << block
        self
    end

    #
    # Like {#after_run} but will not be removed after it's run.
    #
    # @return   [Arachni::HTTP] self
    #
    def after_run_persistent( &block )
        add_after_run_persistent( &block )
        self
    end

    #
    # Makes a generic request
    #
    # @param  [URI]  url
    # @param  [Hash] opts
    # @param  [Block] block     callback
    #
    # @return [Typhoeus::Request]
    #
    def request( url = @url, opts = {}, &block )
        raise 'URL cannot be empty.' if !url

        params    = opts[:params] || {}
        #remove_id = opts[:remove_id]
        train     = opts[:train]
        timeout   = opts[:timeout]
        cookies   = opts[:cookies] || {}
        async     = opts[:async]
        async     = true if async.nil?
        headers   = opts[:headers] || {}

        update_cookies  = opts[:update_cookies]
        follow_location = opts[:follow_location] || false

        #
        # the exception jail function wraps the block passed to it
        # in exception handling and runs it
        #
        # how cool is Ruby? Seriously....
        #
        exception_jail {

            if !opts[:no_cookiejar]
                cookies = begin
                    @cookie_jar.for_url( url ).inject({}) do |h, c|
                        h[c.name] = c.value
                        h
                    end.merge( cookies )
                rescue => e
                    print_error "Could not get cookies for URL '#{url}' from Cookiejar (#{e})."
                    print_error_backtrace e
                    cookies
                end
            end

            headers           = @headers.merge( headers )
            headers['Cookie'] ||= cookies.map { |k, v| "#{cookie_encode( k )}=#{cookie_encode( v )}" }.join( ';' )

            headers.delete( 'Cookie' ) if headers['Cookie'].empty?
            headers.each { |k, v| headers[k] = ::URI.encode( v, "\r\n" ) if v }

            # if we are going to train (i.e. parse the response and feed the new
            # page back to the framework) we need a way to keep track of
            # what we tainted
            #params = params.merge( @rand_seed => '' ) if train

            #
            # There are cases where the url already has a query and we also have
            # some params to work with. Some webapp frameworks will break
            # or get confused...plus the url will not be RFC compliant.
            #
            # Thus we need to merge the provided params with the
            # params of the url query and remove the latter from the url.
            #
            cparams = params.dup
            curl    = normalize_url( url ).dup

            if opts[:method] != :post
                begin
                    parsed = uri_parse( curl )
                    cparams = parse_url_vars( curl ).merge( cparams )
                    curl.gsub!( "?#{parsed.query}", '' ) if parsed.query
                rescue
                    return
                end
            else
                cparams = cparams.inject( {} ) do |h, (k, v)|
                    h[form_encode( k )] = form_encode( v ) if v && k
                    h
                end
            end

            opts = {
                headers: headers,
                params:  cparams.empty? ? nil : cparams,
                method:  opts[:method].nil? ? :get : opts[:method],
                body:    opts[:body]
            }.merge( @opts )

            opts[:follow_location] = follow_location if follow_location
            opts[:timeout]         = timeout if timeout

            req = Typhoeus::Request.new( curl, opts )
            req.train if train
            req.update_cookies if update_cookies
            queue( req, async, &block )
            req
        }
    end

    #
    # Gets a URL passing the provided query parameters
    #
    # @param  [URI]  url     URL to GET
    # @param  [Hash] opts    request options
    #                         * :params  => request parameters || {}
    #                         * :train   => force Arachni to analyze the HTML code || false
    #                         * :async   => make the request async? || true
    #                         * :headers => HTTP request headers  || {}
    #                         * :follow_location => follow redirects || false
    #
    # @param    [Block] block   callback to be passed the response
    #
    # @return [Typhoeus::Request]
    #
    def get( url = @url, opts = { }, &block )
        request( url, opts, &block )
    end

    #
    # Posts a form to a URL with the provided query parameters
    #
    # @param  [URI]   url     URL to POST
    # @param  [Hash]  opts    request options
    #                          * :params  => request parameters || {}
    #                          * :train   => force Arachni to analyze the HTML code || false
    #                          * :async   => make the request async? || true
    #                          * :headers => HTTP request headers  || {}
    #
    # @param    [Block] block   callback to be passed the response
    #
    # @return [Typhoeus::Request]
    #
    def post( url = @url, opts = { }, &block )
        request( url, opts.merge( method: :post ), &block )
    end

    #
    # Sends an HTTP TRACE request to "url".
    #
    # @param  [URI]   url     URL to POST
    # @param  [Hash]  opts    request options
    #                          * :params  => request parameters || {}
    #                          * :train   => force Arachni to analyze the HTML code || false
    #                          * :async   => make the request async? || true
    #                          * :headers => HTTP request headers  || {}
    #
    # @param    [Block] block   callback to be passed the response
    #
    # @return [Typhoeus::Request]
    #
    def trace( url = @url, opts = { }, &block )
        request( url, opts.merge( method: :trace ), &block )
    end


    #
    # Gets a url with cookies and url variables
    #
    # @param  [URI]   url      URL to GET
    # @param  [Hash]  opts    request options
    #                          * :params  => cookies || {}
    #                          * :train   => force Arachni to analyze the HTML code || false
    #                          * :async   => make the request async? || true
    #                          * :headers => HTTP request headers  || {}
    #
    # @param    [Block] block   callback to be passed the response
    #
    # @return [Typhoeus::Request]
    #
    def cookie( url = @url, opts = { }, &block )
        opts[:cookies] = (opts[:params] || {}).dup
        opts[:params]  = nil
        request( url, opts, &block )
    end

    #
    # Gets a url with optional url variables and modified headers
    #
    # @param  [URI]   url      URL to GET
    # @param  [Hash]  opts    request options
    #                          * :params  => headers || {}
    #                          * :train   => force Arachni to analyze the HTML code || false
    #                          * :async   => make the request async? || true
    #
    # @param    [Block] block   callback to be passed the response
    #
    # @return [Typhoeus::Request]
    #
    def header( url = @url, opts = { }, &block )
        opts[:headers] = (opts[:params] || {}).dup
        opts[:params]  = nil
        request( url, opts, &block )
    end

    def sandbox( &block )
        h = {}
        instance_variables.each do |iv|
            val = instance_variable_get( iv )
            h[iv] = val.deep_clone rescue val.dup rescue val
        end

        hooks = {}
        @__hooks.each { |k, v| hooks[k] = v.dup }

        ret = block.call( self )

        h.each { |iv, val| instance_variable_set( iv, val ) }
        @__hooks = hooks

        ret
    end

    #
    # Updates the cookie-jar with the passed cookies
    #
    # @param    [Array<Arachni::Parser::Element::Cookie>]   cookies
    #
    def update_cookies( cookies )
        @cookie_jar.update( cookies )
    end
    alias :set_cookies :update_cookies

    #
    # Extracts cookies from an HTTP response and updates the cookie-jar
    #
    # It also executes callbacks added with "add_on_new_cookies( &block )".
    #
    # @param    [Typhoeus::Response]    res
    #
    def parse_and_set_cookies( res )
        cookies = Arachni::Parser::Element::Cookie.from_response( res )
        update_cookies( cookies )

        # update framework cookies
        Arachni::Options.instance.cookies = cookies

        call_on_new_cookies( cookies, res )
    end

    #
    # @param    [Block] block   to be passed the new cookies and the response that set them
    #
    def on_new_cookies( &block )
        add_on_new_cookies( &block )
    end

    #
    # Checks whether or not the provided response is a custom 404 page
    #
    # @param  [Typhoeus::Response]  res  the response to check
    # @param  [Block]   block   to be passed true or false depending on the result
    #
    def custom_404?( res, &block )
        precision = 2

        @_404 ||= {}
        path  = get_path( res.effective_url )
        @_404[path] ||= []

        uri = uri_parse( res.effective_url )
        trv_back = File.dirname( uri.path )
        trv_back_url = uri.scheme + '://' +  uri.host + ':' + uri.port.to_s + trv_back
        trv_back_url += '/' if trv_back_url[-1] != '/'

        # 404 probes
        generators = [
            # get a random path with an extension
            proc{ path + random_string + '.' + random_string[0..precision] },

            # get a random path without an extension
            proc{ path + random_string },

            # move up a dir and get a random file
            proc{ trv_back_url + random_string },

            # move up a dir and get a random file with an extension
            proc{ trv_back_url + random_string + '.' + random_string[0..precision] },

            # get a random directory
            proc{ path + random_string + '/' }
        ]

        @_404_gathered ||= BloomFilter.new

        gathered = 0
        body = res.body
        # (precision - 1).times {
            # get( res.effective_url, :remove_id => true ).on_complete {
                # |c_res|
                # body = body.rdiff( c_res.body )
                # gathered += 1
                # if gathered == generators.size * precision + precision - 1
                    # block.call is_404?( path, body )
                # end
            # }
        # }

        if !@_404_gathered.include?( path )
            generators.each.with_index do |generator, i|
                @_404[path][i] ||= {}

                precision.times {
                    get( generator.call, follow_location: true ) do |c_res|
                        gathered += 1

                        if gathered == generators.size * precision
                            @_404_gathered << path
                            block.call is_404?( path, body )
                        else
                            @_404[path][i]['rdiff_now'] ||= false

                            if !@_404[path][i]['body']
                                @_404[path][i]['body'] = c_res.body
                            else
                                @_404[path][i]['rdiff_now'] = true
                            end

                            if @_404[path][i]['rdiff_now'] && !@_404[path][i]['rdiff']
                                @_404[path][i]['rdiff'] = @_404[path][i]['body'].rdiff( c_res.body )
                            end
                        end
                    end
                }
            end
        else
            block.call is_404?( path, body )
        end
        nil
    end

    def self.method_missing( sym, *args, &block )
        instance.send( sym, *args, &block )
    end

    private

    def hydra_run
        @burst_runtime ||= 0
        @burst_runtime_start = Time.now
        @hydra.run
        @burst_runtime += Time.now - @burst_runtime_start
        @queue_size = 0
    end

    #
    # Queues a Tyhpoeus::Request and calls the following callbacks:
    # * on_queue() -- intersects a queued request and gets passed the original
    #   and the async method. If the block returns one or more request
    #   objects these will be queued instead of the original request.
    # * on_complete() -- calls the block with the each requests as it arrives.
    #
    # @param  [Tyhpoeus::Request]  req  the request to queue
    # @param  [Bool]  async  run request async?
    # @param  [Block]  block  callback
    #
    def queue( req, async = true, &block )
        requests   = call_on_queue( req, async )
        requests ||= req

        [requests].flatten.reject { |p| !p.is_a?( Typhoeus::Request ) }.
            each { |request| forward_request( request, async, &block ) }
    end

    #
    # Performs the actual queueing of requests, passes them to Hydra and sets
    # up callbacks and hooks.
    #
    # @param    [Typhoeus::Request]     req
    # @param    [Bool]      async
    # @param  [Block]  block  callback
    #
    def forward_request( req, async = true, &block )
        req.id = @request_count

        @queue_size += 1
        !async ? @hydra_sync.queue( req ) : @hydra.queue( req )

        @request_count += 1

        print_debug '------------'
        print_debug 'Queued request.'
        print_debug "ID#: #{req.id}"
        print_debug "URL: #{req.url}"
        print_debug "Method: #{req.method}"
        print_debug "Params: #{req.params}"
        print_debug "Headers: #{req.headers}"
        print_debug "Train?: #{req.train?}"
        print_debug  '------------'

        req.on_complete( true ) do |res|

            @response_count += 1
            @curr_res_cnt   += 1
            @curr_res_time  += res.start_transfer_time

            call_on_complete( res )

            parse_and_set_cookies( res ) if req.update_cookies?

            print_debug '------------'
            print_debug 'Got response.'
            print_debug "Request ID#: #{res.request.id}"
            print_debug "URL: #{res.effective_url}"
            print_debug "Method: #{res.request.method}"
            print_debug "Params: #{res.request.params}"
            print_debug "Headers: #{res.request.headers}"
            print_debug "Train?: #{res.request.train?}"
            print_debug '------------'

            if res.timed_out?
                print_bad 'Request timed-out! -- ID# ' + res.request.id.to_s
                @time_out_count += 1
            end

            if req.train?
                # handle redirections
                if res.redirection? && res.location.is_a?( String )
                    get( to_absolute( res.location, trainer.page.url ) ) do |res2|
                        @trainer.push( res2 )
                    end
                else
                    @trainer.push( res )
                end
            end
        end

        req.on_complete( &block ) if block_given?

        hydra_run if emergency_run?

        exception_jail { @hydra_sync.run } if !async
    end

    def emergency_run?
        @queue_size >= MAX_QUEUE_SIZE
    end

    def is_404?( path, body )
        @_404[path].each { |_404| return true if _404['body'].rdiff( body ) == _404['rdiff'] }
        false
    end

    def random_string
        Digest::SHA1.hexdigest( rand( 9999999 ).to_s )
    end

    def self.info
        { name: 'HTTP' }
    end

end
end
