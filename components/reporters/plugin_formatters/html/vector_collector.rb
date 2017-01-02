=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::HTML

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::VectorCollector < Arachni::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML

        <% results.each do |url, vectors| %>
            <h3>
                <a href="<%= escapeHTML url %>">
                    <%= escapeHTML url %>
                </a>
            </h3>

            <% vectors.each do |vector| %>
                <h4>
                    <%= vector['type'] %> pointing to

                    <a href="<%= escapeHTML vector['action'] %>">
                        <%= escapeHTML vector['action'] %>
                    </a>
                </h4>

                <% if vector['inputs'] %>
                    <ul>
                    <% vector['inputs'].each do |name, value| %>
                        <li>
                            <strong><%= escapeHTML name %>:</strong>
                            <%= escapeHTML value.inspect %>
                        </li>
                    <% end %>
                    </ul>
                <% end %>

                <% if vector['source'] %>
                    <pre><%= escapeHTML vector['source'] %></pre>
                <% end %>

            <% end %>
        <% end %>
        HTML
    end

end
end
