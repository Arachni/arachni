=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::HTML

#
# HTML formatter for the results of the HealthMap plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::HealthMap < Arachni::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
            <style type="text/css">
                a.without_issues {
                    color: blue
                }
                a.with_issues {
                    color: red
                }
            </style>

            <% results['map'].each do |entry|
                    state, url = entry.to_a.first
                %>

                <a class="<%= state %>" href="<%= escapeHTML url %>"><%= escapeHTML url %></a>
                <br/>
            <% end %>

            <br/>

            <h3>Stats</h3>

            <strong>Total</strong>: <%= results['total'] %> <br/>
            <strong>Safe</strong>: <%= results['without_issues'] %> <br/>
            <strong>Unsafe</strong>: <%= results['with_issues'] %> <br/>
            <strong>Issue percentage</strong>: <%= results['issue_percentage'] %>%
        HTML
    end

end
end
