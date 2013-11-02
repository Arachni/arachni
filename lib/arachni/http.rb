=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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
lib = Options.dir['lib']
require lib + 'typhoeus/utils'
require lib + 'typhoeus/hydra'
require lib + 'typhoeus/request'
require lib + 'typhoeus/response'
require lib + 'utilities'
require lib + 'mixins/observable'

#
# Provides a system-wide, simple and high-performance HTTP interface.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class HTTP
    include Singleton
    include Module::Output
    include Utilities
    include Mixins::Observable

    #
    # {HTTP} error namespace.
    #
    # All {HTTP} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    #
    class Error < Arachni::Error
    end

    require Options.dir['lib'] + 'http/cookie_jar'

    # Default maximum concurrency for HTTP requests.
    MAX_CONCURRENCY = 20

    # Default maximum redirect limit.
    REDIRECT_LIMIT  = 20

    # Don't let the request queue grow more than this amount, if it does then
    # run the queued requests to unload it.
    MAX_QUEUE_SIZE  = 500

    # Default 1 minute timeout for HTTP requests.
    HTTP_TIMEOUT    = 60_000

    # Maximum size of the cache that holds 404 signatures.
    CUSTOM_404_CACHE_SIZE = 250

    # Maximum allowed difference (in tokens) when comparing custom 404 signatures.
    CUSTOM_404_SIGNATURE_THRESHOLD  = 25

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

    def initialize
        reset
    end

    #
    # Re-initializes the singleton
    #
    # @return   [Arachni::HTTP] self
    #
    def reset( hooks_too = true )
        clear_observers if hooks_too

        opts = Options

        req_limit = opts.http_req_limit || MAX_CONCURRENCY

        hydra_opts = {
            max_concurrency: req_limit,
            method:          :auto
        }

        @url = opts.url.to_s
        @url = nil if @url.empty?

        @hydra      = Typhoeus::Hydra.new( hydra_opts )
        @hydra_sync = Typhoeus::Hydra.new( hydra_opts.merge( max_concurrency: 1 ) )

        @hydra.disable_memoization
        @hydra_sync.disable_memoization

        @headers = {
            'Accept'          => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Encoding' => 'gzip, deflate',
            'User-Agent'      => opts.user_agent
        }
        @headers['From'] = opts.authed_by if opts.authed_by

        @headers.merge!( opts.custom_headers )

        @cookie_jar = CookieJar.new( opts.cookie_jar )
        update_cookies( opts.cookies ) if opts.cookies
        update_cookies( opts.cookie_string ) if opts.cookie_string

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
            timeout:                       opts.http_timeout || HTTP_TIMEOUT,
            username:                      opts.http_username,
            password:                      opts.http_password
        }.merge( proxy_opts )

        @request_count  = 0
        @response_count = 0
        @time_out_count = 0

        @curr_res_time = 0
        @curr_res_cnt  = 0
        @burst_runtime = 0

        @queue_size = 0

        @after_run = []

        @_404 = Hash.new
        self
    end

    # Runs all queued requests
    def run
        exception_jail {
            @burst_runtime = nil

            begin
                hydra_run

                duped_after_run = @after_run.dup
                @after_run.clear
                duped_after_run.each { |block| block.call }
            end while @queue_size > 0

            call_after_run_persistent

            # Prune the custom 404 cache after callbacks have been called.
            prune_custom_404_cache

            @curr_res_time = 0
            @curr_res_cnt  = 0
            true
        }
    rescue SystemExit
        raise
    rescue
        nil
    end

    # Aborts the running requests on a best effort basis
    def abort
        exception_jail { @hydra.abort }
    end

    # @return   [Integer]
    #   Amount of time (in seconds) that the current burst has been running.
    def burst_runtime
        @burst_runtime.to_i > 0 ?
            @burst_runtime : Time.now - (@burst_runtime_start || Time.now)
    end

    # @return   [Integer]
    #   Average response time for the running requests (i.e. the current burst).
    def average_res_time
        return 0 if @curr_res_cnt == 0
        @curr_res_time / @curr_res_cnt
    end

    # @return   [Integer]
    #   Responses/second for the running requests (i.e. the current burst).
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

    # @return   [Integer]   Current maximum concurrency of HTTP requests.
    def max_concurrency
        @hydra.max_concurrency
    end

    # @return   [Array<Arachni::Element::Cookie>]   All cookies in the jar.
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
    # Makes a generic request.
    #
    # @param  [URI]   url
    # @param  [Hash]  opts    Request options.
    # @option opts [Hash]  :params ({}) Request parameters.
    # @option opts [Hash]  :train   (false)
    #   Force Arachni to analyze the HTML code looking for new elements.
    # @option opts [Hash]  :async   (true) Make the request async?
    # @option opts [Hash]  :headers ({}) Extra HTTP request headers.
    # @param  [Block] block  Callback to be passed the response.
    #
    # @return [Typhoeus::Request]
    #
    def request( url = @url, opts = {}, &block )
        fail ArgumentError, 'URL cannot be empty.' if !url

        params    = opts[:params] || {}
        train     = opts[:train]
        timeout   = opts[:timeout]
        cookies   = opts[:cookies] || {}
        async     = opts[:async]
        async     = true if async.nil?
        headers   = opts[:headers] || {}

        update_cookies  = opts[:update_cookies]
        follow_location = opts[:follow_location] || false

        username = opts.delete( :username )
        password = opts.delete( :password )

        exception_jail( false ) do

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
            headers['Cookie'] ||= cookies.map do |k, v|
                "#{cookie_encode( k, :name )}=#{cookie_encode( v )}"
            end.join( ';' )

            headers.delete( 'Cookie' ) if headers['Cookie'].empty?
            headers.each { |k, v| headers[k] = Header.encode( v ) if v }

            # There are cases where the url already has a query and we also have
            # some params to work with. Some webapp frameworks will break
            # or get confused...plus the url will not be RFC compliant.
            #
            # Thus we need to merge the provided params with the
            # params of the url query and remove the latter from the url.
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
            opts[:timeout]         = timeout  if timeout
            opts[:username]        = username if username
            opts[:password]        = password if password

            req = Typhoeus::Request.new( curl, opts )
            req.train if train
            req.update_cookies if update_cookies
            queue( req, async, &block )
            req
        end
    end

    #
    # Gets a URL passing the provided query parameters.
    #
    # @param  (see #request)
    # @return (see #request)
    #
    # @see #request
    #
    def get( url = @url, opts = {}, &block )
        request( url, opts, &block )
    end

    #
    # Posts a form to a URL with the provided query parameters.
    #
    # @param  (see #request)
    # @return (see #request)
    #
    # @see #request
    #
    def post( url = @url, opts = {}, &block )
        request( url, opts.merge( method: :post ), &block )
    end

    #
    # Sends an HTTP TRACE request to "url".
    #
    # @param  (see #request)
    # @return (see #request)
    #
    # @see #request
    #
    def trace( url = @url, opts = {}, &block )
        request( url, opts.merge( method: :trace ), &block )
    end


    #
    # Gets a url with cookies and url variables
    #
    # @param  (see #request)
    # @return (see #request)
    #
    # @see #request
    #
    def cookie( url = @url, opts = {}, &block )
        opts[:cookies] = (opts[:params] || {}).dup
        opts[:params]  = nil
        request( url, opts, &block )
    end

    #
    # Gets a url with optional url variables and modified headers
    #
    # @param  (see #request)
    # @return (see #request)
    #
    # @see #request
    #
    def header( url = @url, opts = {}, &block )
        opts[:headers] ||= {}
        opts[:headers].merge! ((opts[:params] || {}).dup )

        opts[:params]  = nil
        request( url, opts, &block )
    end

    #
    # Executes a `block` under a sandbox.
    #
    # Cookies or new callbacks set as a result of the block won't affect the
    # HTTP singleton.
    #
    # @param    [Block] block
    #
    # @return   [Object]    Return value of the block.
    #
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
    # Updates the cookie-jar with the passed cookies.
    #
    # @param    [Array<String, Hash, Arachni::Element::Cookie>]   cookies
    #
    def update_cookies( cookies )
        @cookie_jar.update( cookies )

        # Update framework cookies.
        Arachni::Options.cookies = @cookie_jar.cookies
    end
    alias :set_cookies :update_cookies

    #
    # Extracts cookies from an HTTP response and updates the cookie-jar.
    #
    # It also executes callbacks added with `add_on_new_cookies( &block )`.
    #
    # @param    [Typhoeus::Response]    res
    #
    def parse_and_set_cookies( res )
        cookies = Cookie.from_response( res )
        update_cookies( cookies )

        call_on_new_cookies( cookies, res )
    end

    # @param    [Block] block
    #   To be passed the new cookies and the response that set them
    def on_new_cookies( &block )
        add_on_new_cookies( &block )
    end

    #
    # Checks whether or not the provided response is a custom 404 page
    #
    # @param  [Typhoeus::Response]  res  The response to check.
    # @param  [Block]   block
    #   To be passed true or false depending on the result.
    #
    def custom_404?( res, &block )
        path = get_path( res.effective_url )

        return block.call( is_404?( path, res.body ) ) if has_custom_404_signature?( path )

        precision  = 2
        generators = custom_404_probe_generators( res.effective_url, precision )

        gathered_responses = 0
        expected_responses = generators.size * precision

        generators.each.with_index do |generator, i|
            _404_signatures_for_path( path )[i] ||= {}

            precision.times do
                get( generator.call, follow_location: true ) do |c_res|
                    gathered_responses += 1

                    if _404_signatures_for_path( path )[i][:body]
                        _404_signatures_for_path( path )[i][:rdiff] =
                            _404_signatures_for_path( path )[i][:body].
                                refine( c_res.body )

                        next if gathered_responses != expected_responses

                        has_custom_404_signature( path )
                        block.call is_404?( path, res.body )
                    else
                        _404_signatures_for_path( path )[i][:body] =
                            Support::Signature.new(
                                c_res.body, threshold: CUSTOM_404_SIGNATURE_THRESHOLD
                            )
                    end
                end
            end
        end

        nil
    end

    def self.method_missing( sym, *args, &block )
        instance.send( sym, *args, &block )
    end

    private

    def prune_custom_404_cache
        return if @_404.size <= CUSTOM_404_CACHE_SIZE

        @_404.keys.each do |path|
            # If the path hasn't been analyzed yet don't even consider
            # removing it. Technically, at this point (after #hydra_run) there
            # should not be any non analyzed paths but better be sure.
            next if !@_404[path][:analyzed]

            # We've done enough...
            return if @_404.size < CUSTOM_404_CACHE_SIZE

            @_404.delete( path )
        end
    end

    # @return  [Array<Proc>]
    #   Generators for paths which should elicit a 404 response.
    def custom_404_probe_generators( url, precision )
        uri  = uri_parse( url )
        path = uri.up_to_path

        trv_back     = File.dirname( uri.path )
        trv_back_url = uri.scheme + '://' +  uri.host + ':' + uri.port.to_s + trv_back
        trv_back_url += '/' if trv_back_url[-1] != '/'

        [
            # Get a random path with an extension.
            proc { path + random_string + '.' + random_string[0..precision] },

            # Get a random path without an extension.
            proc { path + random_string },

            # Move up a dir and get a random file.
            proc { trv_back_url + random_string },

            # Move up a dir and get a random file with an extension.
            proc { trv_back_url + random_string + '.' + random_string[0..precision] },

            # Get a random directory.
            proc { path + random_string + '/' }
        ]
    end

    def _404_data_for_path( path )
        @_404[path] ||= {
            analyzed:   false,
            signatures: []
        }
    end

    def is_404?( path, body )
        @_404[path][:signatures].each do |_404|
            return true if _404[:body].refine( body ) == _404[:rdiff]
        end
        false
    end

    def _404_signatures_for_path( path )
        _404_data_for_path( path )[:signatures]
    end

    def has_custom_404_signature?( path )
        _404_data_for_path( path )[:analyzed]
    end

    def has_custom_404_signature( path )
        _404_data_for_path( path )[:analyzed] = true
    end

    def hydra_run
        @running = true
        @burst_runtime ||= 0
        @burst_runtime_start = Time.now
        @hydra.run
        @queue_size = 0
        @running = false
        @burst_runtime += Time.now - @burst_runtime_start
    end

    #
    # Queues a {Typhoeus::Request} and calls the following callbacks:
    # * on_queue() -- intersects a queued request and gets passed the original
    #   and the async method. If the block returns one or more request
    #   objects these will be queued instead of the original request.
    # * on_complete() -- calls the block with the each requests as it arrives.
    #
    # @param  [Typhoeus::Request]  req  the request to queue
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
        if emergency_run?
            print_info 'Request queue reached its maximum size, performing an emergency run.'
            hydra_run
        end

        req.id = @request_count

        @queue_size += 1
        !async ? @hydra_sync.queue( req ) : @hydra.queue( req )

        @request_count += 1

        if debug?
            print_debug '------------'
            print_debug 'Queued request.'
            print_debug "ID#: #{req.id}"
            print_debug "URL: #{req.url}"
            print_debug "Method: #{req.method}"
            print_debug "Params: #{req.params}"
            print_debug "Headers: #{req.headers}"
            print_debug "Train?: #{req.train?}"
            print_debug  '------------'
        end

        req.on_complete( true ) do |res|

            @response_count += 1
            @curr_res_cnt   += 1
            @curr_res_time  += res.start_transfer_time

            call_on_complete( res )

            parse_and_set_cookies( res ) if req.update_cookies?

            if debug?
                print_debug '------------'
                print_debug "Got response for request ID#: #{res.request.id}"
                print_debug "Status: #{res.code}"
                print_debug "Error msg: #{res.curl_error_message}"
                print_debug "URL: #{res.effective_url}"
                print_debug "Headers:\n#{res.headers}"
                print_debug "Parsed headers: #{res.headers_hash}"
            end

            if res.timed_out?
                print_debug "Request timed-out! -- ID ##{res.request.id}"
                @time_out_count += 1
            end

            print_debug '------------'
        end

        req.on_complete( &block ) if block_given?

        exception_jail { @hydra_sync.run } if !async
    end

    def emergency_run?
        @queue_size >= MAX_QUEUE_SIZE && !@running
    end

    def random_string
        Digest::SHA1.hexdigest( rand( 9999999 ).to_s )
    end

    def self.info
        { name: 'HTTP' }
    end

end
end
