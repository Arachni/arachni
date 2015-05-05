=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Extract paths from HTML comments.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1.1
class Arachni::Parser::Extractors::Comments < Arachni::Parser::Extractors::Base

    def run( doc )
        doc.xpath( '//comment()' ).map do |comment|
            comment.text.scan( /(\/[\/a-zA-Z0-9%._-]+)/ )
        end.flatten.select { |s| s.include? '/' }
    end

end
