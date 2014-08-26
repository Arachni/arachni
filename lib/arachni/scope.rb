=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni

# Determines whether or not resources (URIs, pages, elements, etc.) are {#out?}
# of the scan {OptionGroups::Scope scope}.
#
# @abstract
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Scope

    # {Scope} error namespace.
    #
    # All {Scope} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::Error
    end

    # @return   [OptionGroups::Scope]
    def options
        Options.scope
    end

    # @return   [Bool]
    #   `true` if the resource is out of scope, `false` otherwise.
    #
    # @abstract
    def out?
    end

end

end
