=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::OptionGroups

# Holds login options for the {Arachni::Framework}'s {Arachni::Session} manager.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Login < Arachni::OptionGroup

    # @return   [String]
    #   URL whose {Arachni::HTTP::Response response} {Arachni::HTTP::Response#body}
    #   should match {#check_pattern} when a valid webapp {Arachni::Session session}
    #   has been established.
    #
    # @see Session
    attr_accessor :check_url

    # @return   [String]
    #   Pattern which should match the {#check_url} {Arachni::HTTP::Response response}
    #   {Arachni::HTTP::Response#body} when a valid webapp {Session session} has
    #   been established.
    #
    # @see Session
    attr_accessor :check_pattern

    def validate
        return {} if (check_url && check_pattern) || (!check_url && !check_pattern)

        {
            (check_url ? :check_pattern : :check_url) =>
                'Option is missing.'
        }
    end

end
end
