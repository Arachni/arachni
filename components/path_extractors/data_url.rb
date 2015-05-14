=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Extracts paths from anchor elements.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Arachni::Parser::Extractors::DataURL < Arachni::Parser::Extractors::Base

    # Returns an array of paths as plain strings
    #
    # @param    [Nokogiri]  doc
    #   Nokogiri document.
    #
    # @return   [Array<String>]
    #   Paths.
    def run( doc )
        doc.search( '//a[@data-url]' ).map { |a| a['data-url'] }
    end

end
