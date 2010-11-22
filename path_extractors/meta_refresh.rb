=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Anemone::Extractors

#
# Extracts meta refresh URLs.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class MetaRefresh < Paths

    #
    # Returns an array of paths as plain strings
    #
    # @param    [Nokogiri]  Nokogiri document
    #
    # @return   [Array<String>]  paths
    #
    def run( doc )
        begin
            doc.search( "//meta[@http-equiv='refresh']" ).
                map { |url| url['content'].split( ';' )[1].split( '=' )[1] }
        rescue
        end
    end

end
end
