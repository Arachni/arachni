=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Extracts paths from "link" HTML elements.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.2
class Arachni::Parser::Extractors::Links < Arachni::Parser::Extractors::Base

    def run
        return [] if !includes?( 'link' )

        document.search( '//link[@href]' ).map { |a| a['href'] }
    end

end
