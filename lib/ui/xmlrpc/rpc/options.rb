=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

#
# Overloads the Options class adding support for direct parsing.
#
# Not much to look at but it streamlines XML-RPC option handling.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Options

    def reset
        @exclude    = []
        @include    = []
        @redundant  = []
        @exclude_cookies    = []
    end

    def include=( arr )
        @include = arr.map{ |rule| Regexp.new( rule ) }
        return true
    end

    def exclude=( arr )
        @exclude = arr.map{ |rule| Regexp.new( rule ) }
        return true
    end

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
