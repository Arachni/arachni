=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'typhoeus'
require 'singleton'

module Arachni

lib = Options.paths.lib
require lib + 'typhoeus/hydra'
require lib + 'mixins/observable'

module HTTP

require_relative 'headers'
require_relative 'message'
require_relative 'request'
require_relative 'response'

#
# {HTTP} error namespace.
#
# All {HTTP} errors inherit from and live under it.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Error < Arachni::Error
end

#
# Provides a system-wide, simple and high-performance HTTP client.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Client
    include Singleton
    include UI::Output
    include Utilities
    include Mixins::Observable

    personalize_output

    #
    # {Client} error namespace.
    #
    # All {Client} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    #
    class Error < Arachni::HTTP::Error
    end

    require Options.paths.lib + 'http/cookie_jar'

    # Default maximum concurrency for HTTP requests.
    MAX_CONCURRENCY = 20

    # Default 1 minute timeout for HTTP requests.
    HTTP_TIMEOUT = 60_000

    # Maximum size of the cache that holds 404 signatures.
    CUSTOM_404_CACHE_SIZE = 250

    # Maximum allowed difference (in tokens) when comparing custom 404 signatures.
    CUSTOM_404_SIGNATURE_THRESHOLD = 25

    # @return   [String]    Framework target URL, used as reference.
    attr_reader :url

    # @return    [Hash]     Default headers for {Request requests}.
    attr_reader :headers

    # @return   [Integer]   Amount of performed requests.
    attr_reader :request_count

    # @return   [Integer]   Amount of received responses.
    attr_reader :response_count

    # @return   [Integer]   Amount of timed-out requests.
    attr_reader :time_out_count

    # @return   [Integer]
    #   Sum of the response times for the running requests (of the current burst).
    attr_reader :burst_response_time_sum

    # @return   [Integer]
    #   Amount of responses received for the running requests (of the current burst).
    attr_reader :burst_response_count

    def initialize
        reset
    end

    # Re-initializes the singleton
    #
    # @return   [Arachni::HTTP] self
    def reset( hooks_too = true )
        clear_observers if hooks_too
        State.http.clear

        opts = Options

        @url = opts.url.to_s
        @url = nil if @url.empty?

        @hydra = Typhoeus::Hydra.new( max_concurrency: opts.http.request_concurrency || MAX_CONCURRENCY )

        headers.merge!(
            'Accept'     => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'User-Agent' => opts.http.user_agent
        )
        headers['From'] = opts.authorized_by if opts.authorized_by
        headers.merge!( opts.http.request_headers )

        cookie_jar.load( opts.http.cookie_jar_filepath ) if opts.http.cookie_jar_filepath
        update_cookies( opts.http.cookies )
        update_cookies( opts.http.cookie_string ) if opts.http.cookie_string

        reset_burst_info

        @request_count  = 0
        @response_count = 0
        @time_out_count = 0

        @total_response_time_sum = 0
        @total_runtime           = 0

        @queue_size = 0

        @after_run = []

        @_404 = Hash.new
        @mutex = Monitor.new
        self
    end

    # @return    [CookieJar]
    def cookie_jar
        State.http.cookiejar
    end

    def headers
        State.http.headers
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
            @curr_res_cnt = 0
            true
        }
    rescue SystemExit
        raise
    rescue
        nil
    end

    # @note Cookies or new callbacks set as a result of the block won't affect
    #   the HTTP singleton.
    #
    # @param    [Block] block   Block to executes  inside a sandbox.
    #
    # @return   [Object]    Return value of the block.
    def sandbox( &block )
        h = {}
        instance_variables.each do |iv|
            val = instance_variable_get( iv )
            h[iv] = val.deep_clone rescue val.dup rescue val
        end

        hooks = {}
        @__hooks.each { |k, v| hooks[k] = v.dup } if @__hooks

        pre_cookies = cookies.deep_clone
        pre_headers = headers.deep_clone

        ret = block.call( self )

        cookie_jar.clear
        update_cookies pre_cookies

        headers.clear
        headers.merge! pre_headers

        h.each { |iv, val| instance_variable_set( iv, val ) }
        @__hooks = hooks

        ret
    end

    # Aborts the running requests on a best effort basis.
    def abort
        exception_jail { @hydra.abort }
    end

    # @return   [Integer]
    #   Amount of time (in seconds) that has been devoted to performing requests
    #   and getting responses.
    def total_runtime
        @total_runtime > 0 ? @total_runtime : burst_runtime
    end

    # @return   [Float]
    #   Average response time for all requests.
    def total_average_response_time
        return 0 if @response_count == 0
        @total_response_time_sum / Float( @response_count )
    end

    # @return   [Float] Responses/second.
    def total_responses_per_second
        if @response_count > 0 && total_runtime > 0
            return @response_count / Float( total_runtime )
        end
        0
    end

    # @return   [Float]
    #   Amount of time (in seconds) that the current burst has been running.
    def burst_runtime
        @burst_runtime.to_i > 0 ?
            @burst_runtime : Time.now - (@burst_runtime_start || Time.now)
    end

    # @return   [Float]
    #   Average response time for the running requests (i.e. the current burst).
    def burst_average_response_time
        return 0 if @burst_response_count == 0
        @burst_response_time_sum / Float( @burst_response_count )
    end

    # @return   [Float]
    #   Responses/second for the running requests (i.e. the current burst).
    def burst_responses_per_second
        if @burst_response_count > 0 && burst_runtime > 0
            return @burst_response_count / burst_runtime
        end
        0
    end

    # @param   [Integer]   concurrency
    #   Sets the maximum concurrency of HTTP requests.
    def max_concurrency=( concurrency )
        @hydra.max_concurrency = concurrency
    end

    # @return   [Integer]   Current maximum concurrency of HTTP requests.
    def max_concurrency
        @hydra.max_concurrency
    end

    # @return   [Array<Arachni::Element::Cookie>]   All cookies in the jar.
    def cookies
        cookie_jar.cookies
    end

    # Gets called each time a hydra {#run} completes.
    #
    # @param    [Block] block   Callback.
    #
    # @return   [Arachni::HTTP] self
    def after_run( &block )
        @after_run << block
        self
    end

    # Like {#after_run} but will not be removed after it has been called.
    #
    # @param    [Block] block   Callback.
    #
    # @return   [Arachni::HTTP] self
    def after_run_persistent( &block )
        add_after_run_persistent( &block )
        self
    end

    # Queues/performs a generic request.
    #
    # @param  [String]   url   URL to request.
    # @param  [Hash]  options
    #   {Request#initialize Request options} with the following extras:
    # @option options [Hash]  :cookies   ({})
    #   Extra cookies to use for this request.
    # @option options [Hash]  :no_cookiejar   (false)
    #   Do not include cookies from the {#cookie_jar}.
    # @param  [Block] block  Callback to be passed the {Response response}.
    #
    # @return [Request, Response]
    #   {Request} when operating in `:async:` `:mode` (the default), {Response}
    #   when in `:async:` `:mode`.
    def request( url = @url, options = {}, &block )
        fail ArgumentError, 'URL cannot be empty.' if !url

        cookies = options.delete( :cookies ) || {}

        exception_jail( false ) {
            if !options.delete( :no_cookiejar )
                cookies = begin
                    cookie_jar.for_url( url ).inject({}) do |h, c|
                        h[c.name] = c.value
                        h
                    end.merge( cookies )
                rescue => e
                    print_error "Could not get cookies for URL '#{url}' from Cookiejar (#{e})."
                    print_error_backtrace e
                    cookies
                end
            end

            request = Request.new( options.merge(
                url:     url,
                headers: headers.merge( options.delete( :headers ) || {} ),
                cookies: cookies
            ))

            if block_given?
                request.on_complete( &block )
            end

            queue( request )
            return request.run if request.blocking?
            request
        }
    end

    # Performs a `GET` {Request request}.
    #
    # @param  (see #request)
    # @return (see #request)
    #
    # @see #request
    def get( url = @url, options = {}, &block )
        request( url, options, &block )
    end

    # Performs a `POST` {Request request}.
    #
    # @param  (see #request)
    # @return (see #request)
    #
    # @see #request
    def post( url = @url, options = {}, &block )
        options[:body] = (options.delete( :parameters ) || {}).dup
        request( url, options.merge( method: :post ), &block )
    end

    # Performs a `TRACE` {Request request}.
    #
    # @param  (see #request)
    # @return (see #request)
    #
    # @see #request
    def trace( url = @url, options = {}, &block )
        request( url, options.merge( method: :trace ), &block )
    end


    # Performs a `GET` {Request request} sending the cookies in `:parameters`.
    #
    # @param  (see #request)
    # @return (see #request)
    #
    # @see #request
    def cookie( url = @url, options = {}, &block )
        options[:cookies] = (options.delete( :parameters ) || {}).dup
        request( url, options, &block )
    end

    # Performs a `GET` {Request request} sending the headers in `:parameters`.
    #
    # @param  (see #request)
    # @return (see #request)
    #
    # @see #request
    def header( url = @url, options = {}, &block )
        options[:headers] ||= {}
        options[:headers].merge!( (options.delete( :parameters ) || {}).dup )
        request( url, options, &block )
    end

    # Queues a {Request} and calls the following callbacks:
    #
    # * `#on_queue` -- intersects a queued request and gets passed the original
    #       and the async method. If the block returns one or more request
    #       objects these will be queued instead of the original request.
    # * `#on_complete` -- calls the block with the each requests as it arrives.
    #
    # @param  [Request]  request  the request to queue
    def queue( request )
        requests   = call_on_queue( request )
        requests ||= request

        [requests].flatten.reject { |p| !p.is_a?( Request ) }.
            each { |request| forward_request( request ) }
    end

    # @param    [Array<String, Hash, Arachni::Element::Cookie>]   cookies
    #   Updates the cookie-jar with the passed `cookies`.
    def update_cookies( cookies )
        cookie_jar.update( cookies )
        cookie_jar.cookies
    end
    alias :set_cookies :update_cookies

    # @note Executes callbacks added with `add_on_new_cookies( &block )`.
    #
    # @param    [Response]    response
    #   Extracts cookies from `response` and updates the cookie-jar.
    def parse_and_set_cookies( response )
        cookies = Cookie.from_response( response )
        update_cookies( cookies )

        call_on_new_cookies( cookies, response )
    end

    # @param    [Block] block
    #   To be passed the new cookies and the response that set them
    def on_new_cookies( &block )
        add_on_new_cookies( &block )
    end

    # @param  [Response]  response
    #   Checks whether or not the provided response is a custom 404 page.
    # @param  [Block]   block
    #   To be passed true or false depending on the result.
    def custom_404?( response, &block )
        path = get_path( response.url )

        return block.call( is_404?( path, response.body ) ) if has_custom_404_signature?( path )

        precision = 2
        generators = custom_404_probe_generators( response.url, precision )

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
                        block.call is_404?( path, response.body )
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

    # @return [Array<Proc>]
    # Generators for paths which should elicit a 404 response.
    def custom_404_probe_generators( url, precision )
        uri = uri_parse( url )
        path = uri.up_to_path

        trv_back = File.dirname( uri.path )
        trv_back_url = uri.scheme + '://' + uri.host + ':' + uri.port.to_s + trv_back
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

        reset_burst_info

        @hydra.run

        @queue_size = 0
        @running    = false

        @burst_runtime += Time.now - @burst_runtime_start
        @total_runtime += @burst_runtime
    end

    def reset_burst_info
        @burst_response_time_sum = 0
        @burst_response_count    = 0
        @burst_runtime           = 0
        @burst_runtime_start     = Time.now
    end

    # Performs the actual queueing of requests, passes them to Hydra and sets
    # up callbacks and hooks.
    #
    # @param    [Request]     request
    def forward_request( request )
        request.id = @request_count

        if debug?
            print_debug '------------'
            print_debug 'Queued request.'
            print_debug "ID#: #{request.id}"
            print_debug "URL: #{request.url}"
            print_debug "Method: #{request.method}"
            print_debug "Params: #{request.parameters}"
            print_debug "Body: #{request.body}"
            print_debug "Headers: #{request.headers}"
            print_debug "Train?: #{request.train?}"
            print_debug  '------------'
        end

        request.on_complete do |response|
            synchronize do
                @response_count          += 1
                @burst_response_count    += 1
                @burst_response_time_sum += response.time
                @total_response_time_sum += response.time

                if Platform::Manager.fingerprint?( response )
                    # Force a fingerprint by converting the Response to a Page object.
                    response.to_page
                end

                call_on_complete( response )

                parse_and_set_cookies( response ) if request.update_cookies?

                if debug?
                    print_debug '------------'
                    print_debug "Got response for request ID#: #{response.request.id}"
                    print_debug "Status: #{response.code}"
                    print_debug "Error msg: #{response.return_message}"
                    print_debug "URL: #{response.url}"
                    print_debug "Headers:\n#{response.headers_string}"
                    print_debug "Parsed headers: #{response.headers}"
                end

                if response.timed_out?
                    print_debug "Request timed-out! -- ID# #{response.request.id}"
                    @time_out_count += 1
                end

                print_debug '------------'
            end
        end

        synchronize { @request_count += 1 }

        return if request.blocking?

        @hydra.queue( request.to_typhoeus )
        @queue_size += 1

        if emergency_run?
            print_info 'Request queue reached its maximum size, performing an emergency run.'
            hydra_run
        end

        request
    end

    def emergency_run?
        @queue_size >= Options.http.request_queue_size && !@running
    end

    def is_404?( path, body )
        @_404[path][:signatures].each do |_404|
            return true if _404[:rdiff].similar? _404[:body].refine( body )
        end
        false
    end

    def random_string
        Digest::SHA1.hexdigest( rand( 9999999 ).to_s )
    end

    def synchronize( &block )
        @mutex.synchronize( &block )
    end


    def self.info
        { name: 'HTTP' }
    end

end
end
end
