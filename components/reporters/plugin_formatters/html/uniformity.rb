=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::HTML

# HTML formatter for the results of the Uniformity plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::Uniformity < Arachni::Plugin::Formatter

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
        <ul>
        <% results.each do |digests| %>
            <% issue = report.issue_by_digest( digests.first ) %>
            <li>
                <%= CGI.escapeHTML( issue.name ) %> in <%= issue.vector.type %> variable
                '<%= issue.vector.affected_input_name %>' using <%= issue.vector.method.to_s.upcase %> at the following pages:
                <ul>

                <% digests.each do |digest|%>
                    <li>
                        <%= CGI.escapeHTML( report.issue_by_digest( digest ).vector.action ) %>
                    </li>
                <%end%>

                </ul>
            </li>
        <%end%>
        </ul>
        HTML
    end

end
end
