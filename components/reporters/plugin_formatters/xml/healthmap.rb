=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Reporters::XML

# XML formatter for the results of the HealthMap plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::HealthMap < Arachni::Plugin::Formatter

    def run( xml )
        xml.map {
            results['map'].each do |i|
                xml.send( i.keys[0], i.values[0] )
            end
        }

        xml.total results['total']
        xml.with_issues results['with_issues']
        xml.without_issues results['without_issues']
        xml.issue_percentage results['issue_percentage']
    end

end
end
