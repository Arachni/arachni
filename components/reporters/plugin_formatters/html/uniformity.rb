=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Reporters::HTML

# HTML formatter for the results of the Uniformity plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::Uniformity < Arachni::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
        <ul>
        <% results.each do |digests| %>
            <% issue = report.issue_by_digest( digests.first ) %>
            <li>
                <strong><%= escapeHTML issue.name %></strong> in <code><%= issue.vector.type %></code> input
                <code><%= issue.affected_input_name %></code> using
                <code><%= issue.vector.method.to_s.upcase %></code> at the following pages:

                <ul class="list-unstyled">
                    <% digests.each do |digest|
                        issue = report.issue_by_digest( digest )
                        url   = escapeHTML( issue.vector.action )
                    %>
                    <li>
                        <a class="btn btn-xs btn-info"
                           href="<%= issue_location( issue ) %>"
                           title="Inspect issue"
                        >
                            <i class="fa fa-eye"></i>
                        </a>

                        <a href="<%= url %>"><%= url %></a>
                    </li>
                    <% end %>
                </ul>
            </li>
        <%end%>
        </ul>
        HTML
    end

end
end
