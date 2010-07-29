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

module Anemone

#
# Overides Anemone's Core class method skip_link?( link )
# to support regexp matching to the whole url and enforce redundancy checks.
# <br/>
# Messages were also added to inform the user in case of redundant URLs.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1-pre
#
class Core

    include Arachni::UI::Output

    #
    # Returns +true+ if *link* should not be visited because
    # its URL matches a skip_link pattern or the reundancy countdown has reached
    # zero.
    #
    def skip_link?( link )

        url = link.to_s
        skip = false
        @opts[:redundant].each_with_index {
            |redundant, i|

            if( url =~ redundant['regexp'] )

                if( @opts[:redundant][i]['count'] == 0 )
                    print_verbose( 'Discarding redundant page: \'' + url + '\'' )
                    return true
                end

                print_info( 'Matched redundancy rule: ' +
                redundant['regexp'].to_s + ' for page \'' +
                url + '\'' )

                print_info( 'Count-down: ' +
                @opts[:redundant][i]['count'].to_s )

                @opts[:redundant][i]['count'] -= 1
            end
        }

        @skip_link_patterns.any? { |pattern| url =~ pattern }

    end

    #
    # Execute the on_every_page blocks for *page*
    #
    # Modified it to fix a bug in Anemone when given more than one<br/>
    # regular expression for "@on_pages_like_blocks".
    #
    def do_page_blocks(page)
        @on_every_page_blocks.each do |block|
            block.call(page)
        end

        @on_pages_like_blocks.each do |patterns, blocks|
            if matches_pattern?( page.url.to_s, patterns )
                blocks.each { |block| block.call(page) }
            end
        end
    end
    
    #
    # Decides whether or not a url matches any of the regular expressions
    # in "patterns".
    #
    # @param    [String]    url
    # @param    [Array]     patterns    array of regular expressions
    #
    # @return    [Bool]
    #
    def matches_pattern?( url, patterns )
        
        patterns.each {
            |pattern|
                return true if url =~ pattern
        }
        
        return false
    end

end

end
