=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Extracts paths from `script` HTML elements.
# Both from `src` and the text inside the scripts.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Parser::Extractors::Scripts < Arachni::Parser::Extractors::Base

    def run
        return [] if !check_for?( 'script' )

        document.nodes_by_name( 'script' ).map do |s|
            [s['src']].flatten.compact | from_text( s.text.to_s )
        end
    end

    def from_text( text )
        text.scan( /[\/a-zA-Z0-9%._-]+/ ).
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
