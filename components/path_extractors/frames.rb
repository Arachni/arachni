=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Extracts paths from frames.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.2
class Arachni::Parser::Extractors::Frames < Arachni::Parser::Extractors::Base

    def run
        return [] if !includes?( 'frame' )

        document.css( 'frame', 'iframe' ).
            map { |a| a.attributes['src'].content rescue next }
    end

end
