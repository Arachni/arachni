=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::HTML

#
# HTML formatter for the results of the Uniformity plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::Uniformity < Arachni::Plugin::Formatter

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
            <ul>
            <% results['uniformals'].each do |id, uniformal| %>
                <% issue = uniformal['issue'] %>
                <li>
                    <%=issue['name']%> in <%=issue['elem']%> variable
                    '<%=issue['var']%>' using <%=issue['method']%> at the following pages:
                    <ul>

                    <% results['pages'][id].each_with_index do |url, i|%>
                        <li>
                            [<%=uniformal['indices'][i]%>] <a href="#issue_<%=uniformal['indices'][i]%>"><%=url%></a>
                        </li>
                    <%end%>

                    </ul>
                </li>
            <%end%>
            </ul>
        HTML
    end

end
end
