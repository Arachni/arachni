=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module HTTP
class Response

# Determines the {Scope scope} status of {Response}s.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Scope < Message::Scope

    # {Scope} error namespace.
    #
    # All {Scope} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Message::Scope::Error
    end

    # @param    [Arachni::HTTP::Response]  response
    def initialize( response )
        super response

        @response = response
    end

    # @note Also takes into account the {URI::Scope} of the {Message#url}.
    #
    # @return   [Bool]
    #   `true` if the {Response} is out of {OptionGroups::Scope scope},
    #   `false` otherwise.
    #
    # @see #exclude_content?
    # @see #exclude_as_binary?
    def out?
        super || exclude_as_binary? || exclude_content?
    end

    # @return   [Bool]
    #   `true` if {OptionGroups::Scope#exclude_binaries?} and not {Response#text?},
    #   `false` otherwise.
    #
    # @see OptionGroups::Scope#exclude_binaries
    def exclude_as_binary?
        options.exclude_binaries? && !@response.text?
    end

    # @return   [Bool]
    #   `true` if {Message#body} matches an
    #   {OptionGroups::Scope#exclude_content_patterns} pattern, `false` otherwise.
    #
    # @see OptionGroups::Scope#exclude_content_patterns
    def exclude_content?
        !!options.exclude_content_patterns.find { |i| @response.body =~ i }
    end

end

end
end
end
