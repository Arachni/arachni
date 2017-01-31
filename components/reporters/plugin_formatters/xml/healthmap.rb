=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
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
