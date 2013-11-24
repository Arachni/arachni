=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::Stdout

#
# Stdout formatter for the results of the TimingAttacks plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::TimingAttacks < Arachni::Plugin::Formatter

    def run
        print_info 'Relevant issues:'
        print_info '--------------------'
        results.each do |issue|
            print_ok "[\##{issue['index']}] #{issue['name']} at " +
                "#{issue['url']} in #{issue['elem']} variable" +
                " '#{issue['var']}' using #{issue['method']}."
        end
    end

end
end
