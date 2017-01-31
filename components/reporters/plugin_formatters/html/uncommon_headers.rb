=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::HTML

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
                <a href="<%= escapeHTML url %>"><%= escapeHTML url %></a>

                <dl class="dl-horizontal">
                    <% headers.each do |name, value| %>
                        <dt><%= escapeHTML name %></dt>
                        <dd><code><%= escapeHTML value %></code></dd>
                    <% end %>
                </dl>

            </li>
        <% end %>
        </ul>
        HTML
    end

end
end
