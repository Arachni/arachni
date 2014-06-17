=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::HTML

#
# HTML formatter for the results of the FormDicattack plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::FormDicattack < Arachni::Plugin::Formatter
    include TemplateUtilities

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
