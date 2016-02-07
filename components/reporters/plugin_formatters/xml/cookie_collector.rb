=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

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
                xml.url result['response']['url']

                xml.cookies {
                    result['cookies'].each do |name, value|
                        xml.cookie( name: name, value: value )
                    end
                }
            }
        end
    end

end
end
