=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Reporters::XML

# XML formatter for the results of the ContentTypes plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::ContentTypes < Arachni::Plugin::Formatter

    def run( xml )
        results.each do |type, infos|
            infos.each do |info|
                xml.entry {
                    xml.content_type type
                    xml.url  info['url']
                    xml.method_ info['method']

                    info['parameters'].each do |name, value|
                        xml.parameters {
                            xml.name name
                            xml.value value
                        }
                    end
                }
            end
        end
    end

end
end
