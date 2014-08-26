=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

#
# Extracts paths from "form" HTML elements.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1.1
#
class Arachni::Parser::Extractors::Forms < Arachni::Parser::Extractors::Base

    #
    # Returns an array of paths as plain strings
    #
    # @param    [Nokogiri]  doc  Nokogiri document
    #
    # @return   [Array<String>]  paths
    #
    def run( doc )
        doc.search( '//form[@action]' ).map { |a| a['action'] }
    end

end
