=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::XML

#
# XML formatter for the results of the TimingAttacks plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::TimingAttacks < Arachni::Plugin::Formatter
    include Buffer

    def run
        results.each do |issue|
            append "<issue hash=\"#{issue['hash'].to_s}\" " +
               " index=\"#{issue['index'].to_s}\" name=\"#{issue['name']}\"" +
               " url=\"#{issue['url']}\" element=\"#{issue['elem']}\" " +
               " variable=\"#{issue['var']}\" method=\"#{issue['method']}\" />"
        end

        buffer
    end

end
end
