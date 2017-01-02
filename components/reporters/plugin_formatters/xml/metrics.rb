=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::XML

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::Metrics < Arachni::Plugin::Formatter

    def run( xml )
        results.each do |category, data|
            xml.send( category ) {
                data.each do |k, v|
                    if category == 'platforms'
                        v = v.join( ',' )
                    end

                    xml.send k, v
                end
            }
        end
    end

end
end
