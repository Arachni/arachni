=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Extracts paths from "link" HTML elements.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Parser::Extractors::Links < Arachni::Parser::Extractors::Base

    def run
        return [] if !check_for?( 'link' )

        document.nodes_by_name( 'link' ).map { |l| l['href'] }
    end

end
