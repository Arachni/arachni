=begin
    Copyright 2010-2022 Ecsypno <http://www.ecsypno.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Extracts paths from frames.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Parser::Extractors::Frames < Arachni::Parser::Extractors::Base

    def run
        return [] if !check_for?( 'frame' )

        document.nodes_by_names( ['frame', 'iframe'] ).map { |n| n['src'] }
    end

end
