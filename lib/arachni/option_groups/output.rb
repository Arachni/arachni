=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni::OptionGroups

# {Arachni::UI::Output} options.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Output < Arachni::OptionGroup

    # @return   [Bool]
    #   `true` if the output of the RPC instances should be redirected to a
    #   file, `false` otherwise.
    attr_accessor :reroute_to_logfile

end
end
