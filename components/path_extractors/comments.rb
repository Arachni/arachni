=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Extract paths from HTML comments.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.2.1
class Arachni::Parser::Extractors::Comments < Arachni::Parser::Extractors::Base

    def run
        return [] if !includes?( '<!--' )

        document.xpath( '//comment()' ).map do |comment|
            comment.text.scan( /(^|\s)(\/[\/a-zA-Z0-9%._-]+)/ )
        end.flatten.select { |s| s.start_with? '/' }
    end

end
