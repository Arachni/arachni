=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::Stdout

#
# Stdout formatter for the results of the HealthMap plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::HealthMap < Arachni::Plugin::Formatter

    def run
        print_info 'Legend:'
        print_ok 'No issues'
        print_bad 'Has issues'
        print_line

        results[:map].each do |i|
            state = i.keys[0]
            url   = i.values[0]

            if state == :unsafe
                print_bad( url )
            else
                print_ok( url )
            end
        end

        print_line

        print_info "Total: #{results[:total]}"
        print_ok "Without issues: #{results[:safe]}"
        print_bad "With issues: #{results[:unsafe]} ( #{results[:issue_percentage].to_s}% )"
    end

end
end
