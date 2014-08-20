=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni

require Options.paths.lib + 'issue/severity/base'

class Issue

# Holds different severity levels.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Severity

    ORDER = [
        :high,
        :medium,
        :low,
        :informational
    ]

    HIGH          = Base.new( :high )
    MEDIUM        = Base.new( :medium )
    LOW           = Base.new( :low )
    INFORMATIONAL = Base.new( :informational )

end
end
end
