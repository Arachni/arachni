=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Extracts paths from "script" HTML elements.<br/>
# Both from "src" and the text inside the scripts.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1.2
class Arachni::Parser::Extractors::Scripts < Arachni::Parser::Extractors::Base

    #
    # Returns an array of paths as plain strings
    #
    # @param    [Nokogiri]  doc  Nokogiri document
    #
    # @return   [Array<String>]  paths
    #
    def run( doc )
        doc.search( '//script[@src]' ).map { |a| a['src'] } |
            doc.xpath( '//script' ).map(&:text).join.
                scan( /[\/a-zA-Z0-9%._-]+/ ).
                select { |s| s.include?( '.' ) && s.include?( '/' ) }
    end

end
