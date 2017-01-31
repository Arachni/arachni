=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::XML

# XML formatter for the results of the CookieCollector plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::CookieCollector < Arachni::Plugin::Formatter

    def run( xml )
        results.each_with_index do |result, i|
            xml.entry {
                xml.time Time.parse( result['time'] ).xmlschema
                xml.url XML.replace_nulls( result['response']['url'] )

                xml.cookies {
                    result['cookies'].each do |name, value|
                        xml.cookie(
                            name:  Arachni::Reporters::XML.replace_nulls( name ),
                            value: Arachni::Reporters::XML.replace_nulls( value )
                        )
                    end
                }
            }
        end
    end

end
end
