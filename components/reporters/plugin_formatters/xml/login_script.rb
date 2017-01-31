=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::XML

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::LoginScript < Arachni::Plugin::Formatter

    def run( xml )
        xml.message results['message']
        xml.status results['status']

        if results['cookies']
            xml.cookies {
                results['cookies'].each { |name, value| xml.cookie name: name, value: value }
            }
        end
    end

end
end
