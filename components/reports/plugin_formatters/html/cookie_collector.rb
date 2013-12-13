=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::HTML

#
# HTML formatter for the results of the CookieCollector plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::CookieCollector < Arachni::Plugin::Formatter
    include Utils

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
            <h3>Cookies</h3>
            <ul>
            <% results.each do |entry| %>
                <li>
                    On <%=entry[:time].to_s%> @ <a href="<%=escapeHTML(entry[:res][:url])%>"><%=escapeHTML(entry[:res][:url])%></a>
                    <br/>
                    Cookies were forced to:
                    <ul>
                        <% entry[:cookies].each do |name, val| %>
                            <li><%=escapeHTML(name)%> = <%=escapeHTML(val)%></li>
                        <%end%>
                    </ul>
                </li>
            <%end%>
            </ul>
        HTML
    end

end
end
