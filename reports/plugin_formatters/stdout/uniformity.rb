=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::Stdout

#
# Stdout formatter for the results of the Uniformity plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::Uniformity < Arachni::Plugin::Formatter

    def run
        print_info 'Relevant issues:'
        print_info '--------------------'

        uniformals = results['uniformals']
        pages      = results['pages']

        uniformals.each_pair do |id, uniformal|
            issue = uniformal['issue']
            print_ok "#{issue['name']} in #{issue['elem']} variable" +
                " '#{issue['var']}' using #{issue['method']} at the following pages:"

            pages[id].each_with_index do |url, i|
                print_info url + " (Issue \##{uniformal['indices'][i]}" +
                    " - Hash ID: #{uniformal['hashes'][i]} )"
            end

            print_line
        end
    end

end
end
