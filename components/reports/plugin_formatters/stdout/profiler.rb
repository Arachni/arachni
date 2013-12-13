=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::Stdout

#
# Stdout formatter for the results of the Profiler plugin
#
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#
# @version 0.1
#
class PluginFormatters::Profiler < Arachni::Plugin::Formatter

    def run
        print_info 'Inputs affecting output:'
        print_line

        results.each do |item|
            output = item['element']['type'].capitalize
            output << " named '#{item['element']['name']}'" if item['element']['name']
            output << " using the '#{item['element']['affected_input_name']}' input" if item['element']['affected_input_name']
            output << " at '#{item['element']['owner']}' pointing to '#{item['element']['action']}'"
            output << " using '#{item['request']['method']}'."

            print_ok output

            print_info 'It was submitted using the following parameters:'
            item['element']['auditable'].each_pair { |k, v| print_info "  * #{k}\t= #{v}" }

            print_info
            print_info "The taint landed in the following elements at '#{item['request']['url']}':"
            item['landed'].each do |elem|

                output = elem['type'].capitalize
                output << " named '#{elem['name']}'" if elem['name']
                output << " using the '#{elem['affected_input_name']}' input" if elem['affected_input_name']
                output << " at '#{elem['owner']}' pointing to '#{elem['action']}'" if elem['action']

                print_info "  * #{output}"
                if elem['auditable']
                    elem['auditable'].each_pair { |k, v| print_info( "    - #{k}\t= #{v}" ) }
                end

            end
        end

    end

end
end
