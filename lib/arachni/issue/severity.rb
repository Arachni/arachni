=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

require Options.paths.lib + 'issue/severity/base'

class Issue

# Holds different severity levels.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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

Arachni::Severity = Arachni::Issue::Severity
