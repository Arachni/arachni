=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Extracts paths from "form" HTML elements.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Parser::Extractors::Forms < Arachni::Parser::Extractors::Base

    def run
        return [] if !check_for?( 'action' )

        document.nodes_by_name( 'form' ).map { |f| f['action'] }
    end

end
