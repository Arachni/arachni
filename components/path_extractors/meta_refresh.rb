=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

#
# Extracts meta refresh URLs.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class Arachni::Parser::Extractors::MetaRefresh < Arachni::Parser::Extractors::Base

    #
    # Returns an array of paths as plain strings
    #
    # @param    [Nokogiri]  doc  Nokogiri document
    #
    # @return   [Array<String>]  paths
    #
    def run( doc )
        doc.search( "//meta[
                translate(
                    @http-equiv,
                        'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                        'abcdefghijklmnopqrstuvwxyz'
                    ) = 'refresh'
            ]" ).map do |url|
            begin
                _, url = url['content'].split( ';', 2 )
                next if !url
                unquote( url.split( '=', 2 ).last )
            rescue
                next
            end
        end
    end

    def unquote( str )
        [ '\'', '"' ].each do |q|
            return str[1...-1] if str.start_with?( q ) && str.end_with?( q )
        end
        str
    end

end
