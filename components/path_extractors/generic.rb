=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'uri'

#
# Extract URLs from arbitrary text.
#
# You might think that this renders the rest path extractors redundant
# but the others can extract paths from HTML attributes, this one can only extract
# full URLs.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.2.1
#
class Arachni::Parser::Extractors::Generic < Arachni::Parser::Extractors::Base

    #
    # Returns an array of paths as plain strings
    #
    # @param    [Nokogiri]  doc  Nokogiri document
    #
    # @return   [Array<String>]  paths
    #
    def run( doc )
        URI.extract( doc.to_s, %w(http https) ).map do |u|
            #
            # This extractor needs to be a tiny bit intelligent because
            # due to its generic nature it'll inevitably match some garbage.
            #
            # For example, if some JS code contains:
            #
            #    var = 'http://blah.com?id=1'
            #
            # or
            #
            #    var = { 'http://blah.com?id=1', 1 }
            #
            #
            # The URI.extract call will match:
            #
            #    http://blah.com?id=1'
            #
            # and
            #
            #    http://blah.com?id=1',
            #
            # respectively.
            #
            if !includes_quotes?( u )
                u
            else
                if html.include?( "'#{u}" )
                    u.split( '\'' ).first
                elsif html.include?( "\"#{u}" )
                    u.split( '"' ).first
                else
                    u
                end
            end
        end
    rescue
        []
    end

    def includes_quotes?( url )
        url.include?( '\'' ) || url.include?( '"' )
    end

end
