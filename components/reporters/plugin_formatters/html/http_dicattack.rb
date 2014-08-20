=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Reporters::HTML

# HTML formatter for the results of the HTTPDicattack plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::HTTPDicattack < Arachni::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
            <h3>Credentials</h3>

            <dl class="dl-horizontal">
                <dt>Username</dt>
                <dd><kbd><%= escapeHTML results['username'] %></kbd></dd>

                <dt>Password</dt>
                <dd><kbd><%= escapeHTML results['password'] %><kbd></dd>
            </dl>
        HTML
    end

end
end
