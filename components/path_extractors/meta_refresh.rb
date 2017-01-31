=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Extracts meta refresh URLs.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Parser::Extractors::MetaRefresh < Arachni::Parser::Extractors::Base

    def run
        return [] if !check_for?( 'http-equiv' )

        document.nodes_by_attribute_name_and_value( 'http-equiv', 'refresh' ).
            map do |url|
                begin
                    _, url = url['content'].split( ';', 2 )
                    next if !url
                    unquote( url.split( '=', 2 ).last.strip )
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
