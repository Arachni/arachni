=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni::Parser::Extractors

#
# Extract URLs from arbitrary text.
#
# You might think that this renders the rest path extractors redundant
# but the others can extract paths from HTML attributes, this one can only extract
# full URLs.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
class Generic < Paths

    #
    # Returns an array of paths as plain strings
    #
    # @param    [Nokogiri]  Nokogiri document
    #
    # @return   [Array<String>]  paths
    #
    def run( doc )
        begin
            html = doc.to_s
            URI.extract( html, ['http', 'https'] ).map {
                |u|

                #
                # This extractor needs to be a tiny bit intelligent because
                # due to its generic nature it'll inevitably match some garbage.
                #
                # For example, if some JS code contains:
                #
                #    var = 'http://blah.com?id=1'
                #
                # or
                #
                #    var = { 'http://blah.com?id=1', 1 }
                #
                #
                # The URI.extract call will match:
                #
                #    http://blah.com?id=1'
                #
                # and
                #
                #    http://blah.com?id=1',
                #
                # respectively.
                #
                #
                if !includes_quotes?( u )
                    u
                else

                    if html.include?( '\'' + u )
                        u.split( '\'' ).first
                    elsif html.include?( '"' + u )
                        u.split( '"' ).first
                    else
                        u
                    end
                end
            }
        rescue
            return []
        end
    end

    def includes_quotes?( url )
        url.include?( '\'' ) || url.include?( '"' )
    end

end
end
