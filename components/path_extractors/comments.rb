=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# Extract paths from HTML comments.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Arachni::Parser::Extractors::Comments < Arachni::Parser::Extractors::Base

    def run( doc )
        doc.xpath( '//comment()' ).map(&:text).join.
            scan( /\s(\/[\/a-zA-Z0-9%._-]+)/ ).flatten.
            select { |s| s.include? '/' }
    end

end
