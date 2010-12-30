=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

#
# Overrides the Options class adding support for direct options parsing.
#
# Not much to look at but it streamlines XML-RPC server option handling.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Options

    #
    # Resets all important options that can affect the scan
    # during framework reuse.
    #
    def reset
        # nil everything out
        self.instance_variables.each {
            |var|

            # do *NOT* nil out @dir, we'll loose our paths!
            next if var.to_s == '@dir'

            begin
                instance_variable_set( var.to_s, nil )
            rescue Exception => e
                ap e.to_s
                ap e.backtrace
            end
        }


        @exclude    = []
        @include    = []
        @redundant  = []
        @lsmod      = []
        @exclude_cookies    = []

        # set some defaults
        @redirect_limit = 20

        # relatively low but will give good performance without bottleneck
        # on low bandwidth conections
        @http_req_limit = 20
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
