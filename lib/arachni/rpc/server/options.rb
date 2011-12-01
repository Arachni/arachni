=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

#
# Overrides the Options class adding support for direct options parsing.
#
# Not much to look at but it streamlines RPC server option handling.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Options

    def set( hash )
        hash.each_pair {
            |k, v|
            begin
                send( "#{k.to_s}=", v )
            rescue Exception => e
                # ap e
                # ap e.backtrace
            end
        }
        true
    end

    def datastore=( hash )
        @datastore = hash
    end

    #
    # Sets the URL include filter.
    #
    # Only URLs matching any of these rules will be crawled.
    #
    # @param    [Array<Regexp>]     arr
    #
    def include=( arr )
        @include = arr.map{ |rule| Regexp.new( rule ) }
        return true
    end

    #
    # Sets the URL exclude filter.
    #
    # URLs matching any of these rules will not be crawled.
    #
    # @param    [Array<Regexp>]     arr
    #
    def exclude=( arr )
        @exclude = arr.map{ |rule| Regexp.new( rule ) }
        return true
    end

    #
    # Sets the redundancy filters.
    #
    # Filter example:
    #     [
    #        {
    #            'regexp'    => 'calendar.php', # URL to apply the filter to
    #            'count'     => 5   # how many times to crawl the url
    #        },
    #        {
    #            'regexp'    => 'gallery.php',
    #            'count'     => 3
    #        }
    #    ]
    #
    # @param     [Array<Hash>]  arr
    #
    def redundant=( arr )
        ruleset = []
        arr.each {
            |rule|
            rule['regexp'] = Regexp.new( rule['regexp'] )
            ruleset << rule
        }
        @redundant = ruleset.dup
        return true
    end

end
end
