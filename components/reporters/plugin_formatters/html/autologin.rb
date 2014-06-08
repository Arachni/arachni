=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::HTML

#
# HTML formatter for the results of the AutoLogin plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::AutoLogin < Arachni::Plugin::Formatter

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
            <% if results[:cookies].is_a?( Hash )%>
            <h3>Cookies were set to:</h3>
            <ul>
            <% results[:cookies].each do |name, val|%>
                <li><%=name%> = <%=val%></li>
            <%end%>
            <ul>
            <%end%>
        HTML
    end

end

end
