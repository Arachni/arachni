=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Goes through all the issues and checks for signs of uniformity using the
# following criteria:
#
#   * Element type (link, form, cookie, header).
#   * Input name.
#   * The check that logged/discovered the issue -- issue type.
#
# If the above are all the same for more than 1 page we have a hit.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.2
class Arachni::Plugins::Uniformity < Arachni::Plugin::Base

    def run
        wait_while_framework_running

        issue_digests = {}
        framework.report.issues.each do |issue|
            next if issue.passive?

            id = "#{issue.check[:shortname]}:#{issue.vector.method}:" <<
                "#{issue.vector.affected_input_name}"
            (issue_digests[id.hash] ||= []) << issue.digest
        end

        issue_digests.reject! { |_, v| v.size == 1 }
        return if issue_digests.empty?

        register_results( issue_digests.values )
    end

    def self.info
        {
            name:        'Uniformity (Lack of central sanitization)',
            description: %q{
Analyzes the scan results and logs issues which persist across different pages.

This is usually a sign for a lack of a central/single point of input sanitization,
a bad coding practise.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            tags:        %w(meta uniformity),
            version:     '0.2'
        }
    end

end
