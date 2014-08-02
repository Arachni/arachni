=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Reporters::XML

# XML formatter for the results of the CookieCollector plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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
