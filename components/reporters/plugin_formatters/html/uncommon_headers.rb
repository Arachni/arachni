=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::HTML

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::UncommonHeaders < Arachni::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
        <ul>
        <% results.each do |url, headers| %>
            <li>
                <a href="<%= url %>"><%= escapeHTML( url ) %></a>

            <ul>
            <% headers.each do |name, value| %>
                <li><%= name %>: <%= value %></li>
            <%end%>
            </ul>

            </li>
        <%end%>
        </ul>
        HTML
    end

end
end
