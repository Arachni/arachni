=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

class Arachni::Reports::Stdout

# Stdout formatter for the results of the HealthMap plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::HealthMap < Arachni::Plugin::Formatter

    def run
        print_info 'Legend:'
        print_ok 'No issues'
        print_bad 'Has issues'
        print_line

        results[:map].sort_by { |_, v| v }.each do |i|
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
