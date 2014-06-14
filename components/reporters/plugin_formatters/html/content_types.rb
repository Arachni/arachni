=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::HTML

# HTML formatter for the results of the ContentTypes plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::ContentTypes < Arachni::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
            <% results.each do |type, responses| %>
                <ul>
                    <li>
                        <%= type %>
                        <ul>
                            <% responses.each do |response| %>
                            <li>
                                URL:
                                    <a href="<%= escapeHTML response['url'] %>">
                                        <%= escapeHTML response['url'] %>
                                    </a>
                                <br/>

                                Method: <%= response['method'] %>

                                <% if response['parameters'] && response['method'] == :post %>
                                    <ul>
                                        <li>Parameters:</li>
                                        <% response['parameters'].each do |name, val| %>
                                        <li>
                                            <%= name %> = <%= val %>
                                        </li>
                                        <% end %>
                                    <ul>
                                <% end %>
                            </li>
                            <% end %>
                        </ul>
                    </li>
                </ul>
            <% end %>
        HTML
    end

end
end
