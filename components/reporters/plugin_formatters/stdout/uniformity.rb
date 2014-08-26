=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Reporters::Stdout

# Stdout formatter for the results of the Uniformity plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::Uniformity < Arachni::Plugin::Formatter

    def run
        print_info 'Relevant issues:'
        print_info '--------------------'

        results.each do |digests|
            issue = report.issue_by_digest( digests.first )
            print_ok "#{issue.name} in #{issue.vector.type} input" <<
                " '#{issue.affected_input_name}' using #{issue.vector.method.to_s.upcase}" <<
                ' at the following pages:'

            digests.each do |digest|
                print_info "  * #{report.issue_by_digest( digest ).vector.action}"
            end

            print_line
        end
    end

end
end
