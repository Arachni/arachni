=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end
require 'rubygems'
require 'anemone'

#
# Overides Anemone's Core class method skip_link?( link )
# to support regexp matching to the whole url
#
module Anemone

class Core

    include Arachni::UI::Output
    
    #
    # Returns +true+ if *link* should not be visited because
    # its URL matches a skip_link pattern.
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

end

end
