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

module Arachni

lib = Options.dir['lib']

require lib + 'bloom_filter'
require lib + 'module/utilities'
require 'nokogiri'
require lib + 'nokogiri/xml/node'

#
# Crawls the target webapp until there are no new paths left.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Spider
    include UI::Output
    include Utilities

    # How many times to retry failed requests.
    MAX_TRIES = 5

    # @return [Arachni::Options]
    attr_reader :opts

    # @return [Array<String>]   URLs that caused redirects
    attr_reader :redirects

    # @return [Array<String>]
    #   URLs that elicited no response from the server.
    #   Not determined by HTTP status codes, we're talking network failures here.
    attr_reader :failures

    #
    # Instantiates Spider class with user options.
    #
    # @param  [Arachni::Options] opts
    #
    def initialize( opts = Options.instance )
        @opts = opts

        @sitemap   = {}
        @redirects = []
        @paths     = []
        @visited   = Set.new

        @on_each_page_blocks     = []
        @on_each_response_blocks = []
        @on_complete_blocks      = []

        @pass_pages       = true
        @pending_requests = 0

        @retries  = {}
        @failures = []

        seed_paths
    end

    def url
        @opts.url
    end

    # @return   [Array<String>]  Working paths, paths that haven't yet been followed.
    #                                You'll actually get a copy of the working paths
    #                                and not the actual object itself;
    #                                if you want to add more paths use {#push}.
    def paths
        @paths.clone
    end

    # @return   [Array<String>] list of crawled URLs
    def sitemap
        @sitemap.keys
    end

    # @return   [Hash<Integer, String>] list of crawled URLs with their HTTP codes
    def fancy_sitemap
        @sitemap
    end

    #
    # Runs the Spider and passes the requested object to the block.
    #
    # @param [Bool] pass_pages_to_block  decides weather the block should be passed [Arachni::Page]s
    #                           or [Typhoeus::Response]s
    # @param [Block] block  to be passed each page as visited
    #
    # @return [Array<String>]   sitemap
    #
    def run( pass_pages_to_block = true, &block )
        return if !@opts.crawl?

        @running = true

        # options could have changed so reseed
        seed_paths

        if block_given?
            pass_pages_to_block ? on_each_page( &block ) : on_each_response( &block )
        end

        while !done?
            wait_if_paused
            while !done? && url = @paths.shift
                wait_if_paused

                visit( url ) do |res|
                    obj = if pass_pages_to_block
                        Page.from_response( res, @opts )
                    else
                        Parser.new( res, @opts )
                    end

                    if @on_each_response_blocks.any?
                        call_on_each_response_blocks( res )
                    end

                    if @on_each_page_blocks.any?
                        call_on_each_page_blocks( pass_pages_to_block ? obj : Page.from_response( res, @opts ) )
                    end

                    distribute( obj.paths )
                end
            end

            http.run
        end

        http.run
        @running = false

        call_on_complete_blocks

        sitemap
    end

    def running?
        !!@running
    end

    # @param    [Block] block
    #   Sets blocks to be called every time a page is visited.
    def on_each_page( &block )
        fail ArgumentError, 'Block is mandatory!' if !block_given?
        @on_each_page_blocks << block
        self
    end

    # @param    [Block]     block
    #   Sets blocks to be called every time a response is received.
    def on_each_response( &block )
        fail ArgumentError, 'Block is mandatory!' if !block_given?
        @on_each_response_blocks << block
        self
    end

    # @param    [Block]    block
    #   Sets blocks to be called once the crawler is done.
    def on_complete( &block )
        fail ArgumentError, 'Block is mandatory!' if !block_given?
        @on_complete_blocks << block
        self
    end

    #
    # Pushes new paths for the crawler to follow; if the crawler has finished
    # it will be awaken when new paths are pushed.
    #
    # The paths will be sanitized and normalized (cleaned up and converted to absolute ones).
    #
    # @param    [String, Array<String>] paths
    #
    # @return   [Bool]  true if push was successful,
    #                       false otherwise (provided empty or paths that must be skipped)
    #
    def push( paths, wakeup = true )
        paths = dedup( paths )
        return false if paths.empty?

        @paths |= paths
        @paths.uniq!

         # REVIEW: This may cause segfaults, Typhoeus::Hydra doesn't like threads.
        Thread.new { run } if wakeup && !running? # wake up the crawler
        true
    end

    # @return [TrueClass, FalseClass] true if crawl is done, false otherwise
    def done?
        idle? || limit_reached?
    end

    # @return [TrueClass, FalseClass] true if the queue is empty and no
    #                                           requests are pending, false otherwise
    def idle?
        @paths.empty? && @pending_requests == 0
    end

    # @return [TrueClass] pauses the system on a best effort basis
    def pause
        @pause = true
    end

    # @return [TrueClass] resumes the system on a best effort basis
    def resume
        @pause = false
        true
    end

    # @return [Bool] true if the system it paused, false otherwise
    def paused?
        @pause ||= false
    end

    private

    def distribute( urls )
        push( urls, false )
    end

    def seed_paths
        @paths |= dedup( url )
        @paths |= dedup( @opts.extend_paths )
    end

    def call_on_each_page_blocks( obj )
        @on_each_page_blocks.each { |b| exception_jail( false ) { b.call( obj ) } }
    end

    def call_on_each_response_blocks( obj )
        @on_each_response_blocks.each { |b| exception_jail( false ) { b.call( obj ) } }
    end

    def call_on_complete_blocks
        @on_complete_blocks.each { |b| exception_jail( false ) { b.call } }
    end

    # @return   [Arachni::HTTP]   HTTP interface
    def http
        HTTP
    end

    #
    # Decides if a URL should be skipped based on weather it:
    # * has previously been {#visited?}
    # * matches a {#redundant?} filter
    # * matches universal {#skip_path?} options like inclusion and exclusion filters
    #
    # @param    [String]    url to check
    #
    # @return   [Bool]  true if any of the 3 filters returns true, false otherwise
    #
    def skip?( url )
        if visited?( url )
            print_debug "Skipping already visited URL: #{url}"
            return true
        end

         if skip_path?( url )
             print_verbose "Skipping out of scope URL: #{url}"
             return true
         end

        false
    end

    def remove_path_params( url )
        uri = ::Arachni::URI( url ).dup
        uri.path = uri.path.split( ';' ).first.to_s
        uri.to_s
    rescue
        nil
    end

    #
    # @param    [String]    url
    #
    # @return   [Bool]  true if the url has already been visited, false otherwise
    #
    def visited?( url )
        @visited.include?( remove_path_params( url ) )
    end

    # @return   [Bool]  true if the link-count-limit has been exceeded, false otherwise
    def limit_reached?
        @opts.link_count_limit_reached? @visited.size
    end

    #
    # Checks if the provided URL matches a redundant filter
    # and decreases its counter if so.
    #
    # If a filter's counter has reached 0 the method returns true.
    #
    # @param    [String]    url
    #
    # @return   [Bool]  true if the url is redundant, false otherwise
    #
    def redundant?( url )
        redundant = super( url ) do |count, regexp, path|
            print_info "Matched redundancy rule: #{regexp} for #{path}"
            print_info "Count-down: #{count}"
        end

        print_verbose "Discarding redundant page: #{url}" if redundant
        redundant
    end

    def auto_redundant?( url )
        return false if !@opts.auto_redundant?
        @auto_redundant ||= Hash.new( 0 )

        h = "#{url.split( '?' ).first}#{parse_query( url ).keys.sort}".hash

        if @auto_redundant[h] >= @opts.auto_redundant
            print_verbose "Discarding auto-redundant page: #{url}"
            return true
        end

        @auto_redundant[h] += 1
        false
    end

    def dedup( paths )
        return [] if !paths || paths.empty?

        [paths].flatten.uniq.compact.map { |p| to_absolute( p, url ) }.
            reject { |p| skip?( p ) }.uniq.compact
    end

    def wait_if_paused
        ::IO::select( nil, nil, nil, 1 ) while( paused? )
    end

    def hit_redirect_limit?
        @opts.redirect_limit > 0 && @opts.redirect_limit <= @followed_redirects
    end

    def visit( url, opts = {}, &block )
        return if skip?( url ) || redundant?( url ) || auto_redundant?( url )
        visited( url )

        @followed_redirects ||= 0
        @pending_requests += 1

        opts = {
            timeout:         nil,
            follow_location: false,
            update_cookies:  true
        }.merge( opts )

        wrap = proc do |res|
            effective_url = normalize_url( res.effective_url )

            if res.redirection?
                @redirects << res.request.url
                location = to_absolute( res.location )
                if hit_redirect_limit? || skip?( location )
                    decrease_pending
                    next
                end
                @followed_redirects += 1
                push location
            end

            if res.code == 0
                @retries[url.hash] ||= 0

                if @retries[url.hash] >= MAX_TRIES
                    @failures << url

                    print_error "Giving up on: #{effective_url}"
                    print_error "Couldn't get a response after #{MAX_TRIES} tries."
                    print_error "Because: #{res.curl_error_message}"
                else
                    @retries[url.hash] += 1
                    repush( url )

                    print_info "Retrying for: #{effective_url}"
                    print_bad "Because: #{res.curl_error_message}"
                    print_line
                end

                decrease_pending
                next
            end

            print_status "[HTTP: #{res.code}] #{effective_url}"
            @sitemap[effective_url] = res.code
            block.call( res )

            decrease_pending
        end

        http.get( url, opts, &wrap )
    rescue
        decrease_pending
        nil
    end

    def decrease_pending
        @pending_requests -= 1
    end

    def visited( url )
        @visited << remove_path_params( url )
    end

    def repush( url )
        @visited.delete remove_path_params( url )
        push url
    end

    def intercept_print_message( msg )
        "Spider: #{msg}"
    end

end
end
