=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'rubygems'
require 'anemone'
require 'nokogiri'

$:.unshift( File.expand_path( File.dirname( __FILE__ ) ) ) 
require 'lib/anemone/core.rb'
require 'lib/anemone/http.rb'
require 'lib/anemone/page.rb'
require 'lib/net/http.rb'
require 'ap'
require 'pp'

module Arachni

#
# Spider class
#    
# Crawls the URL in opts[:url] and grabs the HTML code and headers.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1-pre
#
class Spider

    include Arachni::UI::Output

    #
    # Hash of options passed to initialize( user_opts ).
    #
    # Default:
    #  opts = {
    #        :threads              =>  3,
    #        :discard_page_bodies  =>  false,
    #        :user_agent           =>  "Arachni/0.1",
    #        :delay                =>  0,
    #        :obey_robots_txt      =>  false,
    #        :depth_limit          =>  false,
    #        :link_depth_limit     =>  false,
    #        :redirect_limit       =>  5,
    #        :storage              =>  nil,
    #        :cookies              =>  nil,
    #        :accept_cookies       =>  true
    #  }
    #
    # @return [Hash]
    #
    attr_reader :opts

    #
    # Sitemap, array of links
    #
    # @return [Array]
    #
    attr_reader :sitemap

    #
    # Code block to be executed on each page
    #
    # @return [Proc]
    #
    attr_reader :on_every_page_blocks

    #
    # Constructor <br/>
    # Instantiates Spider class with user options.
    #
    # @param  [{String => Symbol}] opts  hash with option => value pairs
    #
    def initialize( opts )

        @opts = {
            :threads              =>  3,
            :discard_page_bodies  =>  false,
            :delay                =>  0,
            :obey_robots_txt      =>  false,
            :depth_limit          =>  false,
            :link_count_limit     =>  false,
            :redirect_limit       =>  false,
            :storage              =>  nil,
            :cookies              =>  nil,
            :accept_cookies       =>  true,
            :proxy_addr           =>  nil,
            :proxy_port           =>  nil,
            :proxy_user           =>  nil,
            :proxy_pass           =>  nil
        }.merge opts

        @sitemap = []
        @on_every_page_blocks = []

        # if we have no 'include' patterns create one that will match
        # everything, like '.*'
        @opts[:include] =
            @opts[:include].empty? ? [ Regexp.new( '.*' ) ] : @opts[:include]
    end

    #
    # Runs the Spider and passes the url, html
    # and headers Hash
    #
    # @param [Proc] block  a block expecting url, html, cookies
    #
    # @return [Array] array of links, a sitemap
    #
    def run( &block )

        i = 1
        # start the crawl
        Anemone.crawl( @opts[:url], @opts ) {
            |anemone|
            
            # apply 'exclude' patterns
            anemone.skip_links_like( @opts[:exclude] ) if @opts[:exclude]
            
            # apply 'include' patterns and grab matching pages
            # as they are discovered
            anemone.on_pages_like( @opts[:include] ) {
                |page|

                url = page.url.to_s
                
                # something went kaboom, tell the user and skip the page
                if page.error
                    print_error( "[Error: " + (page.error.to_s) + "] " + url )
                    print_debug_backtrace( page.error )
                    next
                end

                # push the url in the sitemap
                @sitemap.push( url )

                print_line
                print_status( "[HTTP: #{page.code}] " + url )
                
                # call the block...if we have one
                if block
                    block.call( url, page.body, page.headers )
                end

                # run blocks specified later 
                @on_every_page_blocks.each {
                    |block|
                    block.call( page )
                }

                # we don't need the HTML doc anymore
                page.discard_doc!( )

                # make sure we obey the link count limit and
                # return if we have exceeded it.
                if( @opts[:link_count_limit] != false &&
                    @opts[:link_count_limit] <= i )
                    return @sitemap.uniq
                end

                i+=1
            }
        }

        return @sitemap.uniq
    end

    #
    # Hook for further analysis of pages, statistics etc.
    #
    # @param [Proc] block code to be executed for every page
    #
    # @return [self]
    #
    def on_every_page( &block )
        @on_every_page_blocks.push( block )
        self
    end

end
end
