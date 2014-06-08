=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::HTML

#
# XML formatter for the results of the HTTPDicattack plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::HTTPDicattack < Arachni::Plugin::Formatter
    include Utils

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
            <h3>Credentials</h3>
            <strong>Username</strong>: <%=escapeHTML( results[:username] )%> <br/>
            <strong>Password</strong>: <%=escapeHTML( results[:password] )%>
        HTML
    end

end
end
