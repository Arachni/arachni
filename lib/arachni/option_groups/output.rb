=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::OptionGroups

# {Arachni::UI::Output} options.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Output < Arachni::OptionGroup

    # @return    [Bool] Output only positive results during the audit?
    #
    # @see UI::Output#print_ok
    attr_accessor :only_positives

    # @return    [Bool] Be verbose?
    #
    # @see UI::Output#print_verbose
    attr_accessor :verbose

    # @return    [Bool] Output debugging messages?
    #
    # @see UI::Output#print_debug
    attr_accessor :debug

    # @return   [Bool]
    #   `true` if the output of the RPC instances should be redirected to a
    #   file, `false` otherwise.
    attr_accessor :reroute_to_logfile

end
end
