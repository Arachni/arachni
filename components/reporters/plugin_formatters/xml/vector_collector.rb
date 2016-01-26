=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::XML

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::VectorCollector < Arachni::Plugin::Formatter

    def run( xml )
        results.each do |url, vectors|
            vectors.each do |vector|
                xml.vector {
                    xml.class_ vector['class']
                    xml.type vector['type']
                    xml.url vector['url']
                    xml.action vector['action']

                    if vector['source']
                        xml.source vector['source']
                    end

                    if vector['method']
                        xml.method_ vector['method']
                    end

                    if vector['inputs']
                        xml.inputs {
                            vector['inputs'].each do |k, v|
                                xml.input( name: k, value: v )
                            end
                        }
                    end
                }
            end
        end
    end

end
end
