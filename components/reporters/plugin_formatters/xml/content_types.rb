=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::XML

# XML formatter for the results of the ContentTypes plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::ContentTypes < Arachni::Plugin::Formatter

    def run( xml )
        results.each do |type, infos|
            infos.each do |info|
                xml.entry {
                    xml.content_type type
                    xml.url  info['url']
                    xml.method_ info['method']

                    xml.parameters {
                        info['parameters'].each do |name, value|
                            xml.parameter(
                                name: Arachni::Reporters::XML.replace_nulls( name ),
                                value: Arachni::Reporters::XML.replace_nulls( value )
                            )
                        end
                    }

                }
            end
        end
    end

end
end
