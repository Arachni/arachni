=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::HTML

#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::Resolver < Arachni::Plugin::Formatter

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
            <h3>Results</h3>
            <table>
                <tr>
                    <th>
                        Hostname
                    </th>
                    <th>
                        IP Address
                    </th>
                </tr>
            <% results.each do |hostname, ipaddress| %>
                <tr>
                    <td>
                    <%= hostname %>
                    </td>
                    <td>
                    <%= ipaddress %>
                    </td>
                </tr>
            <%end%>
            </table>
        HTML
    end

end
end
