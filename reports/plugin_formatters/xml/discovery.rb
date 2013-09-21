=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::XML

#
# XML formatter for the results of the Discovery plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::Discovery < Arachni::Plugin::Formatter
    include Buffer

    def run
        results.each do |issue|
            "<issue hash=\"#{issue['hash'].to_s}\" " +
                " index=\"#{issue['index'].to_s}\" name=\"#{issue['name']}\"" +
                " url=\"#{issue['url']}\" />"
        end

        buffer
    end

end
end
