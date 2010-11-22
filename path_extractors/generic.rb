=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Anemone::Extractors

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
# @version: 0.1
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
        URI.extract( doc.to_s )
    end

end
end
