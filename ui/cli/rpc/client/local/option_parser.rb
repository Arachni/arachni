=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../../../framework/option_parser'

module Arachni
module UI::CLI
module RPC
module Client
class Local

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class OptionParser < UI::CLI::Framework::OptionParser

    def distribution
        separator 'Distribution'

        on( '--instance-spawns SPAWNS', Integer,
            'How many slaves to spawn for a high-performance mult-Instance scan.'
        ) do |spawns|
            options.spawns = spawns
        end
    end

end
end
end
end
end
end
