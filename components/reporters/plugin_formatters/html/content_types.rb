=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::HTML

# HTML formatter for the results of the ContentTypes plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::ContentTypes < Arachni::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
        <ul>
            <% results.each do |type, responses| %>
                <li>
                    <code><%= escapeHTML type %></code>

                    <dl class="dl-horizontal">
                        <% responses.each do |response| %>
                            <dt>
                                <%= response['method'] %>
                            </dt>
                            <dd>
                                <a href="<%= escapeHTML response['url'] %>">
                                    <%= escapeHTML response['url'] %>
                                </a>

                                <ul>
                                <% if response['parameters'] && response['method'].to_s.downcase == 'post' %>
                                    <% response['parameters'].each do |name, val| %>
                                    <li>
                                        <code><%= escapeHTML name %></code>
                                        =
                                        <code><%= escapeHTML val %></code>
                                    </li>
                                    <% end %>
                                <% end %>
                                <ul>
                            </dd>
                        <% end %>
                    </dl>
                </li>
            <% end %>
        </ul>
        HTML
    end

end
end
