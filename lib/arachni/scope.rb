=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
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
