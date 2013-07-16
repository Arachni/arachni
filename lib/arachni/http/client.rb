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
require lib + 'typhoeus/hydra'
require lib + 'utilities'
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
    include Module::Output
    include Utilities
    include Mixins::Observable

    #
    # {Client} error namespace.
    #
    # All {Client} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    #
    class Error < Arachni::HTTP::Error
    end

    require Options.dir['lib'] + 'http/cookie_jar'

    # Default maximum concurrency for HTTP requests.
    MAX_CONCURRENCY = 20

    # Don't let the request queue grow more than this amount, if it does then
    # run the queued requests to unload it
    MAX_QUEUE_SIZE  = 5000

    CUSTOM_404_CACHE_SIZE = 250

    # @return   [String]    Framework target URL, used as reference.
    attr_reader :url

    # @return    [Hash]     Default headers for {Request requests}.
    attr_reader :headers

    # @return    [CookieJar]
    attr_reader :cookie_jar

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

        opts = Options

        @url = opts.url.to_s
        @url = nil if @url.empty?

        @hydra = Typhoeus::Hydra.new( max_concurrency: opts.http_req_limit || MAX_CONCURRENCY )
        @hydra_sync = Typhoeus::Hydra.new( max_concurrency: 1 )

        @headers = {
            'Accept'     => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'User-Agent' => opts.user_agent
        }
        @headers['From'] = opts.authed_by if opts.authed_by

        @headers.merge!( opts.custom_headers )

        @cookie_jar = CookieJar.new( opts.cookie_jar )
        update_cookies( opts.cookies ) if opts.cookies
        update_cookies( opts.cookie_string ) if opts.cookie_string

        @request_count  = 0
        @response_count = 0
        @time_out_count = 0

        @burst_response_time_sum = 0
        @burst_response_count    = 0
        @burst_runtime           = 0

        @total_response_time_sum = 0
        @total_runtime           = 0

        @queue_size = 0

        @after_run = []

        @_404 = Hash.new
        self
    end

    # Runs all queued requests.
    def run
        exception_jail {
            @burst_runtime = nil
            hydra_run

            @after_run.each { |block| block.call }
            @after_run.clear

            call_after_run_persistent

            # Prune the custom 404 cache after callbacks have been called.
            prune_custom_404_cache

            @burst_response_time_sum = 0
            @burst_response_count  = 0
            true
        }
    rescue SystemExit
        raise
    rescue
        nil
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
        @cookie_jar.cookies
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

            request = Request.new( url, options.merge(
                headers: @headers.merge( options.delete( :headers ) || {} ),
                cookies: cookies
            ))

            response = nil
            if block_given?
                request.on_complete( &block )
            elsif request.blocking?
                request.on_complete { |r| response = r }
            end

            queue( request )
            return response if response
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

    # @note Cookies or new callbacks set as a result of the block won't affect
    #   the HTTP singleton.
    #
    # @param    [Block] block   Block to executes  under a sandbox.
    #
    # @return   [Object]    Return value of the block.
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

    # @param    [Array<String, Hash, Arachni::Element::Cookie>]   cookies
    #   Updates the cookie-jar with the passed `cookies`.
    def update_cookies( cookies )
        @cookie_jar.update( cookies )

        # Update framework cookies.
        Arachni::Options.cookies = @cookie_jar.cookies
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
        precision = 2

        path  = get_path( response.url )

        uri = response.parsed_url
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

        gathered = 0
        body = response.body

        if !path_analyzed_for_custom_404?( path )
            generators.each.with_index do |generator, i|
                _404_signatures_for_path( path )[i] ||= {}

                precision.times {
                    get( generator.call, follow_location: true ) do |c_res|
                        gathered += 1

                        if gathered == generators.size * precision
                            path_analyzed_for_custom_404( path )

                            # save the hash of the refined responses, no sense
                            # in wasting space
                            _404_signatures_for_path( path ).each { |c404| c404[:rdiff] = c404[:rdiff].hash }

                            block.call is_404?( path, body )
                        else
                            _404_signatures_for_path( path )[i][:body] ||= c_res.body

                            _404_signatures_for_path( path )[i][:rdiff] =
                                _404_signatures_for_path( path )[i][:body].rdiff( c_res.body )

                            _404_signatures_for_path( path )[i][:rdiff_words] =
                                _404_signatures_for_path( path )[i][:rdiff].words.map( &:hash )
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

    def _404_data_for_path( path )
        @_404[path] ||= {
            analyzed:   false,
            signatures: []
        }
    end

    def _404_signatures_for_path( path )
        _404_data_for_path( path )[:signatures]
    end

    def path_analyzed_for_custom_404?( path )
        _404_data_for_path( path )[:analyzed]
    end

    def path_analyzed_for_custom_404( path )
        _404_data_for_path( path )[:analyzed] = true
    end

    def hydra_run
        @running = true

        @burst_runtime     ||= 0
        @burst_runtime_start = Time.now

        @hydra.run

        @queue_size = 0
        @running    = false

        @burst_runtime += Time.now - @burst_runtime_start
        @total_runtime += @burst_runtime
    end

    # Queues a {Request} and calls the following callbacks:
    #
    # * on_queue() -- intersects a queued request and gets passed the original
    #   and the async method. If the block returns one or more request
    #   objects these will be queued instead of the original request.
    # * on_complete() -- calls the block with the each requests as it arrives.
    #
    # @param  [Request]  request  the request to queue
    def queue( request )
        requests   = call_on_queue( request )
        requests ||= request

        [requests].flatten.reject { |p| !p.is_a?( Request ) }.
            each { |request| forward_request( request ) }
    end

    # Performs the actual queueing of requests, passes them to Hydra and sets
    # up callbacks and hooks.
    #
    # @param    [Request]     request
    def forward_request( request )
        request.id = @request_count

        typhoeus_req = request.to_typhoeus
        @queue_size += 1
        request.blocking? ? @hydra_sync.queue( typhoeus_req ) : @hydra.queue( typhoeus_req )

        @request_count += 1

        print_debug '------------'
        print_debug 'Queued request.'
        print_debug "ID#: #{request.id}"
        print_debug "URL: #{request.url}"
        print_debug "Method: #{request.method}"
        print_debug "Params: #{request.parameters}"
        print_debug "Headers: #{request.headers}"
        print_debug "Train?: #{request.train?}"
        print_debug  '------------'

        request.on_complete do |response|
            @response_count          += 1
            @burst_response_count    += 1
            @burst_response_time_sum += response.time
            @total_response_time_sum += response.time

            call_on_complete( response )

            parse_and_set_cookies( response ) if request.update_cookies?

            print_debug '------------'
            print_debug "Got response for request ID#: #{response.request.id}"
            print_debug "Status: #{response.code}"
            print_debug "Error msg: #{response.return_message}"
            print_debug "URL: #{response.url}"
            print_debug "Headers:\n#{response.headers_string}"
            print_debug "Parsed headers: #{response.headers}"
            print_debug '------------'

            if response.timed_out?
                print_bad "Request timed-out! -- ID# #{response.request.id}"
                @time_out_count += 1
            end
        end

        if emergency_run?
            print_info 'Request queue reached its maximum size, performing an emergency run.'
            hydra_run
        end

        exception_jail { @hydra_sync.run } if request.blocking?
    end

    def emergency_run?
        @queue_size >= MAX_QUEUE_SIZE && !@running
    end

    def is_404?( path, body )
        # give the rDiff algo a shot first hoping that a comparison of
        # refined responses will be enough to give us a clear-cut positive
        @_404[path][:signatures].each do |_404|
            return true if _404[:body].rdiff( body ).hash == _404[:rdiff]
        end

        # if the comparison of the refinements fails, compare them based on how
        # many words are different between them
        @_404[path][:signatures].each do |_404|
            rdiff_body_words = _404[:body].rdiff( body ).words.map( &:hash )
            return true if (
                (_404[:rdiff_words] - rdiff_body_words) -
                (rdiff_body_words - _404[:rdiff_words])
            ).size < 25
        end

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
end
