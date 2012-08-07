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

lib = Arachni::Options.instance.dir['lib']

require lib + 'bloom_filter'
require lib + 'module/utilities'
require 'nokogiri'
require lib + 'nokogiri/xml/node'

module Arachni

#
# Crawls the target webapp until there are no new paths left.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Spider
    include Arachni::UI::Output
    include Arachni::Utilities

    # @return [Arachni::Options]
    attr_reader :opts

    # @return [String]  seed url
    attr_reader :url

    # @return [Array<String>]   URLs that caused redirects
    attr_reader :redirects

    #
    # Instantiates Spider class with user options.
    #
    # @param  [Arachni::Options] opts
    #
    def initialize( opts = Arachni::Options.instance )
        @opts = opts
        @url  = @opts.url.to_s

        @sitemap   = {}
        @redirects = []
        @visited   = BloomFilter.new

        @on_each_page_blocks = []
        @on_complete_blocks  = []

        @pass_pages       = true
        @pending_requests = 0

        @paths = dedup( @url )
        push( @opts.extend_paths )
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
    # @param [Bool] pass_pages_to_block  decides weather the block should be passed [Arachni::Parser::Page]s
    #                           or [Typhoeus::Response]s
    # @param [Block] block  to be passed each page as visited
    #
    # @return [Array<String>]   sitemap
    #
    def run( pass_pages_to_block = pass_pages?, &block )
        return if !@opts.crawl?

        if block_given?
            pass_pages_to_block ? pass_pages : pass_responses
            on_each_page( &block )
        end

        while !done?
            wait_if_paused
            while !done? && url = @paths.shift
                wait_if_paused

                visit( url ) do |res|
                    obj = if pass_pages?
                        Arachni::Parser::Page.from_response( res, @opts )
                    else
                        Parser.new( res, @opts )
                    end

                    call_on_each_page_blocks( pass_pages? ? obj.dup : res )
                    push( obj.paths )
                end
            end

            http.run
        end

        http.run

        call_on_complete_blocks

        sitemap
    end

    # Tells the crawler to pass [Arachni::Parser::Page]s to {#on_each_page} blocks.
    def pass_pages
        @pass_pages = true
    end

    # @return   [Bool]  true unless {#pass_responses} has been called
    def pass_pages?
        @pass_pages
    end

    # Tells the crawler to pass [Typhoeus::Responses]s to {#on_each_page} blocks.
    def pass_responses
        @pass_pages = false
    end

    #
    # Sets blocks to be called every time a page is visited.
    #
    # By default, the blocks will be passed [Arachni::Parser::Page]s;
    # if you want HTTP responses you need to call {#pass_responses}.
    #
    # @param    [Block]     block
    #
    def on_each_page( &block )
        raise 'Block is mandatory!' if !block_given?
        @on_each_page_blocks << block
        self
    end

    #
    # Sets blocks to be called once the crawler is done.
    #
    # @param    [Block]    block
    #
    def on_complete( &block )
        raise 'Block is mandatory!' if !block_given?
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
    def push( paths )
        paths = dedup( paths )
        return false if paths.empty?

        @paths |= paths
        @paths.uniq!

        # REVIEW: This may cause segfaults, Typhoeus::Hydra doesn't like threads.
        #Thread.new { run } if idle? # wake up the crawler
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

    def call_on_each_page_blocks( obj )
        @on_each_page_blocks.each { |b| exception_jail { b.call( obj ) } }
    end

    def call_on_complete_blocks
        @on_complete_blocks.each { |b| exception_jail { b.call } }
    end

    # @return   [Arachni::HTTP]   HTTP interface
    def http
        Arachni::HTTP
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
        visited?( url ) || skip_path?( url )
    end

    #
    # @param    [String]    url
    #
    # @return   [Bool]  true if the url has already been visited, false otherwise
    #
    def visited?( url )
        @visited.include?( url )
    end

    # @return   [Bool]  true if the link-count-limit has been exceeded, false otherwise
    def limit_reached?
        @opts.link_count_limit > 0 && @visited.size >= @opts.link_count_limit
    end

    #
    # Checks is the provided URL matches a redundant filter
    # and decreases its counter if so.
    #
    # If a filter's counter has reached 0 the method returns true.
    #
    # @param    [String]    url
    #
    # @return   [Bool]  true if the url is redundant, false otherwise
    #
    def redundant?( url )
        redundant = @opts.redundant?( url ) do |count, regexp, path|
            print_info "Matched redundancy rule: #{regexp} for #{path}"
            print_info "Count-down: #{count}"
        end

        print_verbose "Discarding redundant page: #{url}" if redundant
        redundant
    end

    def auto_redundant?( url )
        return false if !Options.auto_redundant?
        @auto_redundant ||= Hash.new( 0 )

        h = "#{url.split( '?' ).first}#{parse_query( url ).keys.sort}".hash

        if @auto_redundant[h] >= Options.auto_redundant
            print_verbose "Discarding auto-redundant page: #{url}"
            return true
        end

        @auto_redundant[h] += 1
        false
    end

    def dedup( paths )
        return [] if !paths || paths.empty?

        [paths].flatten.uniq.compact.map { |p| to_absolute( p, @url ) }.
            reject { |p| skip?( p ) }.uniq.compact
    end

    def wait_if_paused
        ::IO::select( nil, nil, nil, 1 ) while( paused? )
    end

    def visit( url, opts = {}, &block )
        return if skip?( url ) || redundant?( url ) || auto_redundant?( url )
        visited( url )

        @pending_requests += 1

        opts = {
            timeout:         nil,
            remove_id:       true,
            follow_location: true,
            update_cookies:  true
        }.merge( opts )

        wrap = proc do |res|
            effective_url = normalize_url( res.effective_url )

            if res.redirection?
                @redirects << res.request.url
                if skip?( effective_url )
                    decrease_pending
                    next
                end
            end

            print_status( "[HTTP: #{res.code}] " + effective_url )
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
        @visited << url
    end

end
end
