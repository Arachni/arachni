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

require Arachni::Options.instance.dir['lib'] + 'ui/cli/output'
require Arachni::Options.instance.dir['lib'] + 'module/utilities'
require 'nokogiri'
require Arachni::Options.instance.dir['lib'] + 'nokogiri/xml/node'

module Arachni

#
# Crawls the URL in opts[:url] and grabs the HTML code and headers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Spider

    include Arachni::UI::Output
    include Arachni::Module::Utilities

    #
    #
    # @return [Options]
    #
    attr_reader :opts

    #
    # Discovered paths
    #
    # @return [Array]
    #
    attr_reader :sitemap

    #
    # URLs that caused redirects
    #
    # @return [Array]
    #
    attr_reader :redirects

    #
    # Constructor <br/>
    # Instantiates Spider class with user options.
    #
    # @param  [Options] opts
    #
    def initialize( opts )
        @opts = opts

        @sitemap   = []
        @redirects = []
        @on_every_page_blocks = []

        @seed_url = @opts.url.to_s

        @extend_paths   = @opts.extend_paths   || []
        @restrict_paths = @opts.restrict_paths || []

        @paths = [ @seed_url ]

        if restricted_to_paths?
            @paths |= @sitemap = @restrict_paths
        else
            @paths |= @extend_paths
        end

        # if we have no 'include' patterns create one that will match
        # everything, like '.*'
        @opts.include =[ Regexp.new( '.*' ) ] if @opts.include.empty?
    end

    def restricted_to_paths?
        !@restrict_paths.empty?
    end

    #
    # Runs the Spider and passes parsed page to the block
    #
    # @param [Block] block
    #
    # @return [Arachni::Parser::Page]
    #
    def run( parse = true, &block )
        return if @opts.link_count_limit == 0

        visited = Set.new

        opts = {
            :timeout    => nil,
            :remove_id  => true,
            :follow_location => true,
            :update_cookies  => true
        }

        # we need a parser in order to have access to skip() in case
        # there's a redirect that shouldn't be followed
        seed_page = http.get( @seed_url, opts.merge( :async => false ) ).response

        print_status( "[HTTP: #{seed_page.code}] " + seed_page.effective_url )

        parser = Parser.new( @opts, seed_page )
        parser.url = @seed_url
        @paths |= parser.paths
        @paths.uniq!

        while !@paths.empty?
            while !@paths.empty? && url = parser.to_absolute( @paths.shift )
                next if visited.include?( url ) || skip?( url )

                wait_if_paused

                visited << url

                http.get( url, opts ).on_complete do |res|
                    next if parser.skip?( res.effective_url )

                    print_status( "[HTTP: #{res.code}] " + res.effective_url )

                    if parse
                        page = Arachni::Parser::Page.from_http_response( res, @opts )
                        paths = page.paths
                        check_url = page.url
                    else
                        c_parser = Parser.new( @opts, res )
                        paths = c_parser.text? ? c_parser.paths : []
                        check_url = c_parser.url
                    end

                    if !restricted_to_paths?
                        @sitemap |= paths

                        if !res.headers_hash['Location'].empty?
                            @redirects << res.request.url
                        end

                        @paths |= @sitemap - visited.to_a
                    end

                    # call the block...if we have one
                    if block
                        exception_jail{
                            if !skip?( check_url )
                                block.call( parse ? page.clone : res )
                            else
                                print_info( 'Matched skip rule.' )
                            end
                        }
                    end
                end

                # make sure we obey the link count limit and
                # return if we have exceeded it.
                if @opts.link_count_limit &&
                    @opts.link_count_limit > 0 &&
                    visited.size >= @opts.link_count_limit
                    http.run
                    return @sitemap.uniq
                end

            end

            http.run
        end

        @sitemap.uniq
    end

    def http
        Arachni::HTTP.instance
    end

    def skip?( url )
        redundant?( url )
    end

    def redundant?( url )
        @opts.redundant.each_with_index {
            |redundant, i|

            if url =~ redundant['regexp']

                if @opts.redundant[i]['count'] == 0
                    print_verbose( 'Discarding redundant page: \'' + url + '\'' )
                    return true
                end

                print_info( 'Matched redundancy rule: ' +
                redundant['regexp'].to_s + ' for page \'' +
                url + '\'' )

                print_info( 'Count-down: ' + @opts.redundant[i]['count'].to_s )

                @opts.redundant[i]['count'] -= 1
            end
        }
        false
    end


    def wait_if_paused
        ::IO::select( nil, nil, nil, 1 ) while( paused? )
    end

    def pause!
        @pause = true
    end

    def resume!
        @pause = false
    end

    def paused?
        @pause ||= false
    end

end
end
