=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::HTML

# HTML formatter for the results of the CookieCollector plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::CookieCollector < Arachni::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
            <ul>
            <% results.each do |entry| %>
                <li>
                    On <strong><%= entry['time'] %></strong> by

                    <a href="<%= escapeHTML entry['response']['url'] %>">
                        <%= escapeHTML entry['response']['url'] %>
                    </a>

                    <ul>
                        <% (entry['response']['headers']['Set-Cookie'] || []).each do |set_cookie| %>
                            <li>
                                <code><%= escapeHTML set_cookie %></code>
                            </li>
                        <% end %>
                    </ul>
                </li>
            <% end %>
            </ul>
        HTML
    end

end
end
