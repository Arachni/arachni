=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module HTTP
class Response

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Scope < URI::Scope

    # {Scope} error namespace.
    #
    # All {Scope} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Arachni::Error
    end

    # @param    [Arachni::HTTP::Response]  response
    def initialize( response )
        super response.parsed_url

        @response = response
    end

    # Determines whether or not the {Arachni::HTTP::Response} should be
    # ignored.
    #
    # @return   [Bool]
    #   `true` if the {Message#body} or {Message#url} matches any of the
    #   exclusion criteria, `false` otherwise.
    #
    # @see #skip_path?
    # @see OptionGroups::Scope#exclude_binaries?
    # @see OptionGroups::Scope#exclude_page?
    def exclude?
        return true if super
        (Options.scope.exclude_binaries? && !@response.text?) || exclude_content?
    end

    # @return   [Bool]
    #   `true` if {Message#body} matches an
    #   {OptionGroups::Scope#exclude_content_patterns} pattern, `false` otherwise.
    #
    # @see OptionGroups::Scope#exclude_content_patterns
    def exclude_content?
        !!Options.scope.exclude_content_patterns.find { |i| @response.body =~ i }
    end

end

end
end
end
