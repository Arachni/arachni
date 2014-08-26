=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Reporters::XML

# XML formatter for the results of the WAF Detector plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::WAFDetector < Arachni::Plugin::Formatter

    def run( xml )
        xml.message results['message']
        xml.status results['status']
    end

end
end
