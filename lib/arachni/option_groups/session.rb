=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::OptionGroups

# Holds login options for the {Arachni::Framework}'s {Arachni::Session} manager.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Session < Arachni::OptionGroup

    # @return   [String]
    #   URL whose {Arachni::HTTP::Response response} {Arachni::HTTP::Response#body}
    #   should match {#check_pattern} when a valid webapp {Arachni::Session session}
    #   has been established.
    #
    # @see Session
    attr_accessor :check_url

    # @return   [Regexp]
    #   Pattern which should match the {#check_url} {Arachni::HTTP::Response response}
    #   {Arachni::HTTP::Response#body} when a valid webapp {Session session} has
    #   been established.
    #
    # @see Session
    attr_accessor :check_pattern

    def check_pattern=( pattern )
        return @check_pattern = nil if !pattern

        @check_pattern = Regexp.new( pattern )
    end

    def validate
        return {} if (check_url && check_pattern) || (!check_url && !check_pattern)

        {
            (check_url ? :check_pattern : :check_url) =>
                'Option is missing.'
        }
    end

    def to_rpc_data
        d = super
        d['check_pattern'] = d['check_pattern'].to_s if d['check_pattern']
        d
    end

end
end
