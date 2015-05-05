=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'typhoeus'
require 'singleton'

module Arachni

require_relative '../ethon/easy'

module HTTP

require_relative 'headers'
require_relative 'message'
require_relative 'request'
require_relative 'response'
require_relative 'client/dynamic_404_handler'

# {HTTP} error namespace.
#
# All {HTTP} errors inherit from and live under it.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Error < Arachni::Error
end

# Provides a system-wide, simple and high-performance HTTP client.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Client
    include Singleton
    include UI::Output
    include Utilities
    include Support::Mixins::Observable

    personalize_output

    # @!method after_run( &block )
    #
    #   @param    [Block] block
    #       Called after the next {#run}.
    #
    #   @return   [Arachni::HTTP::Client]
    #       `self`
    advertise :after_run

    # @!method after_each_run( &block )
    #
    #   @param    [Block] block
    #       Called after each {#run}.
    #
    #   @return   [Arachni::HTTP] self
    advertise :after_each_run

    # @!method on_queue( &block )
    advertise :on_queue

    # @!method on_new_cookies( &block )
    #
    #   @param    [Block] block
    #       To be passed the new cookies and the response that set them
    advertise :on_new_cookies

    # @!method on_complete( &block )
    advertise :on_complete

    # {Client} error namespace.
    #
    # All {Client} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::HTTP::Error
    end

    require Options.paths.lib + 'http/cookie_jar'

    # Default maximum concurrency for HTTP requests.
    MAX_CONCURRENCY = 20

    # Default 1 minute timeout for HTTP requests.
    HTTP_TIMEOUT = 60_000

    # @return   [String]
    #   Framework target URL, used as reference.
    attr_reader :url

    # @return    [Hash]
    #   Default headers for {Request requests}.
    attr_reader :headers

    # @return   [Integer]
    #   Amount of performed requests.
    attr_reader :request_count

    # @return   [Integer]
    #   Amount of received responses.
    attr_reader :response_count

    # @return   [Integer]
    #   Amount of timed-out requests.
    attr_reader :time_out_count

    # @return   [Integer]
    #   Sum of the response times for the running requests (of the current burst).
    attr_reader :burst_response_time_sum

    # @return   [Integer]
    #   Amount of responses received for the running requests (of the current burst).
    attr_reader :burst_response_count

    # @return   [Dynamic404Handler]
    attr_reader :dynamic_404_handler

    def initialize
        super
        reset
    end

    # @return   [Arachni::HTTP]
    #   Reset `self`.
    def reset( hooks_too = true )
        clear_observers if hooks_too
        State.http.clear

        @url = Options.url.to_s
        @url = nil if @url.empty?

        client_initialize

        headers.merge!(
            'Accept'     => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'User-Agent' => Options.http.user_agent
        )
        headers['From'] = Options.authorized_by if Options.authorized_by
        headers.merge!( Options.http.request_headers )

        cookie_jar.load( Options.http.cookie_jar_filepath ) if Options.http.cookie_jar_filepath
        update_cookies( Options.http.cookies )
        update_cookies( Options.http.cookie_string ) if Options.http.cookie_string

        reset_burst_info

        @request_count  = 0
        @response_count = 0
        @time_out_count = 0

        @total_response_time_sum = 0
        @total_runtime           = 0

        @queue_size = 0

        @dynamic_404_handler = Dynamic404Handler.new

        self
    end

    # @return   [Hash]
    #
    #   Hash including HTTP client statistics including:
    #
    #   *  {#request_count}
    #   *  {#response_count}
    #   *  {#time_out_count}
    #   *  {#total_responses_per_second}
    #   *  {#total_average_response_time}
    #   *  {#burst_response_time_sum}
    #   *  {#burst_response_count}
    #   *  {#burst_responses_per_second}
    #   *  {#burst_average_response_time}
    #   *  {#max_concurrency}
    def statistics
       [:request_count, :response_count, :time_out_count,
        :total_responses_per_second, :burst_response_time_sum,
        :burst_response_count, :burst_responses_per_second,
        :burst_average_response_time, :total_average_response_time,
        :max_concurrency].inject({}) { |h, k| h[k] = send(k); h }
    end

    # @return    [CookieJar]
    def cookie_jar
        State.http.cookie_jar
    end

    def headers
        State.http.headers
    end

    # Runs all queued requests
    def run
        exception_jail false do
            @burst_runtime = nil

            begin
                run_and_update_statistics

                duped_after_run = observers_for( :after_run ).dup
                observers_for( :after_run ).clear
                duped_after_run.each { |block| block.call }
            end while @queue_size > 0 || observers_for( :after_run ).any?

            notify_after_each_run

            # Prune the custom 404 cache after callbacks have been called.
            @dynamic_404_handler.prune

            @curr_res_time = 0
            @curr_res_cnt  = 0

            true
        end
    end

    # @note Cookies or new callbacks set as a result of the block won't affect
    #   the HTTP singleton.
    #
    # @param    [Block] block
    #   Block to executes  inside a sandbox.
    #
    # @return   [Object]
    #   Return value of the block.
    def sandbox( &block )
        h = {}
        instance_variables.each do |iv|
            val = instance_variable_get( iv )
            h[iv] = val.deep_clone rescue val.dup rescue val
        end

        saved_observers = dup_observers

        pre_cookies = cookies.deep_clone
        pre_headers = headers.deep_clone

        ret = block.call( self )

        cookie_jar.clear
        update_cookies pre_cookies

        headers.clear
        headers.merge! pre_headers

        h.each { |iv, val| instance_variable_set( iv, val ) }
        set_observers( saved_observers )

        ret
    end

    # Aborts the running requests on a best effort basis.
    def abort
        exception_jail { client_abort }
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

    # @return   [Integer]
    #   Current maximum concurrency of HTTP requests.
    def max_concurrency
        @hydra.max_concurrency
    end

    # @return   [Array<Arachni::Element::Cookie>]
    #   All cookies in the jar.
    def cookies
        cookie_jar.cookies
    end

    # Queues/performs a generic request.
    #
    # @param  [String]   url
    #   URL to request.
    # @param  [Hash]  options
    #   {Request#initialize Request options} with the following extras:
    # @option options [Hash]  :cookies   ({})
    #   Extra cookies to use for this request.
    # @option options [Hash]  :no_cookie_jar   (false)
    #   Do not include cookies from the {#cookie_jar}.
    # @param  [Block] block  Callback to be passed the {Response response}.
    #
    # @return [Request, Response]
    #   {Request} when operating in `:async:` `:mode` (the default), {Response}
    #   when in `:async:` `:mode`.
    def request( url = @url, options = {}, &block )
        fail ArgumentError, 'URL cannot be empty.' if !url

        options = options.dup
        cookies = options.delete( :cookies ) || {}

        exception_jail false do
            if !options.delete( :no_cookie_jar )
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
        end
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

    # @param  [Request]  request
    #   Request to queue.
    def queue( request )
        notify_on_queue( request )
        forward_request( request )
    end

    # @param    [Array<String, Hash, Arachni::Element::Cookie>]   cookies
    #   Updates the cookie-jar with the passed `cookies`.
    def update_cookies( cookies )
        cookie_jar.update( cookies )
        cookie_jar.cookies
    end
    alias :set_cookies :update_cookies

    # @note Runs {#on_new_cookies} callbacks.
    #
    # @param    [Response]    response
    #   Extracts cookies from `response` and updates the cookie-jar.
    def parse_and_set_cookies( response )
        cookies = Cookie.from_response( response )
        update_cookies( cookies )

        notify_on_new_cookies( cookies, response )
    end

    def self.method_missing( sym, *args, &block )
        instance.send( sym, *args, &block )
    end

    def inspect
        s = "#<#{self.class} "
        statistics.each { |k, v| s << "@#{k}=#{v.inspect} " }
        s << '>'
    end

    private

    def run_and_update_statistics
        @running = true

        reset_burst_info
        client_run

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
        add_callbacks = !request.id
        request.id    = @request_count

        if debug_level_3?
            print_debug_level_3 '------------'
            print_debug_level_3 'Queued request.'
            print_debug_level_3 "ID#: #{request.id}"
            print_debug_level_3 "Performer: #{request.performer.inspect}"
            print_debug_level_3 "URL: #{request.url}"
            print_debug_level_3 "Method: #{request.method}"
            print_debug_level_3 "Params: #{request.parameters}"
            print_debug_level_3 "Body: #{request.body}"
            print_debug_level_3 "Headers: #{request.headers}"
            print_debug_level_3 "Cookies: #{request.cookies}"
            print_debug_level_3 "Train?: #{request.train?}"
            print_debug_level_3  '------------'
        end

        if add_callbacks
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

                    notify_on_complete( response )

                    parse_and_set_cookies( response ) if request.update_cookies?

                    if debug_level_3?
                        print_debug_level_3 '------------'
                        print_debug_level_3 "Got response for request ID#: #{response.request.id}"
                        print_debug_level_3 "Performer: #{response.request.performer.inspect}"
                        print_debug_level_3 "Status: #{response.code}"
                        print_debug_level_3 "Code: #{response.return_code}"
                        print_debug_level_3 "Message: #{response.return_message}"
                        print_debug_level_3 "URL: #{response.url}"
                        print_debug_level_3 "Headers:\n#{response.headers_string}"
                        print_debug_level_3 "Parsed headers: #{response.headers}"
                    end

                    if response.timed_out?
                        print_debug_level_3 "Request timed-out! -- ID# #{response.request.id}"
                        @time_out_count += 1
                    end

                    print_debug_level_3 '------------'
                end
            end
        end

        synchronize { @request_count += 1 }

        return if request.blocking?

        if client_queue( request )
            @queue_size += 1

            if emergency_run?
                print_info 'Request queue reached its maximum size, performing an emergency run.'
                run_and_update_statistics
            end
        end

        request
    end

    def client_initialize
        @hydra = Typhoeus::Hydra.new(
            max_concurrency: Options.http.request_concurrency || MAX_CONCURRENCY
        )
    end

    def client_run
        @hydra.run
    end

    def client_abort
        @hydra.abort
    end

    def client_queue( request )
        if request.high_priority?
            @hydra.queue_front( request.to_typhoeus )
        else
            @hydra.queue( request.to_typhoeus )
        end

        true
    end

    def emergency_run?
        @queue_size >= Options.http.request_queue_size && !@running
    end

    def self.info
        { name: 'HTTP' }
    end

end
end
end
