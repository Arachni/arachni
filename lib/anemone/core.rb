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

    #
    # Returns +true+ if *link* should not be visited because
    # its URL matches a skip_link pattern.
    #
    def skip_link?( link )
      @skip_link_patterns.any? { |pattern| link.to_s =~ pattern }
    end

end

end