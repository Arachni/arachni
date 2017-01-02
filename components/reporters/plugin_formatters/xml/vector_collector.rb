=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

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
                    xml.url Arachni::Reporters::XML.replace_nulls( vector['url'] )
                    xml.action Arachni::Reporters::XML.replace_nulls( vector['action'] )

                    if vector['source']
                        xml.source Arachni::Reporters::XML.replace_nulls( vector['source'] )
                    end

                    if vector['method']
                        xml.method_ vector['method']
                    end

                    if vector['inputs']
                        xml.inputs {
                            vector['inputs'].each do |k, v|
                                xml.input(
                                    name:  Arachni::Reporters::XML.replace_nulls( k ),
                                    value: Arachni::Reporters::XML.replace_nulls( v )
                                )
                            end
                        }
                    end
                }
            end
        end
    end

end
end
