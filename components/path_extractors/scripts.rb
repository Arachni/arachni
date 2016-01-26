=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Extracts paths from `script` HTML elements.
# Both from `src` and the text inside the scripts.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.2
class Arachni::Parser::Extractors::Scripts < Arachni::Parser::Extractors::Base

    def run
        return [] if !includes?( 'script' )

        document.search( '//script[@src]' ).map { |a| a['src'] } |
            document.xpath( '//script' ).map(&:text).join.
                scan( /[\/a-zA-Z0-9%._-]+/ ).
                select do |s|
                    # String looks like a path, but don't get fooled by comments.
                    s.include?( '.' ) && s.include?( '/' )  &&
                    !s.include?( '*' ) && !s.start_with?( '//' ) &&

                    # Require absolute paths, otherwise we may get caught in
                    # a loop, this context isn't the most reliable for extracting
                    # real paths.
                    s.start_with?( '/' )
                end
    end

end
