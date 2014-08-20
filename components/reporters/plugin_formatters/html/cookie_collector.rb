=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Reporters::HTML

# HTML formatter for the results of the CookieCollector plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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
