=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::HTML

#
# HTML formatter for the results of the ContentTypes plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::ContentTypes < Arachni::Plugin::Formatter
    include Utils

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
            <% results.each do |type, responses| %>
                <ul>

                    <li>
                        <%=type%>
                        <ul>
                            <% responses.each do |res| %>
                            <li>
                                URL: <a href="<%=escapeHTML(res[:url])%>"><%=escapeHTML(res[:url])%></a><br/>
                                Method: <%=res[:method]%>

                                <% if res[:params] && res[:method].downcase == 'post' %>
                                    <ul>
                                        <li>Parameters:</li>
                                        <%res[:params].each_pair do |name, val|%>
                                        <li>
                                            <%=name%> = <%=val%>
                                        </li>
                                        <%end%>
                                    <ul>
                                <%end%>
                            </li>
                            <%end%>
                        </ul>
                    </li>

                </ul>

            <%end%>
        HTML

    end

end
end
