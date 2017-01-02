=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::HTML

# HTML formatter for the results of the HTTPDicattack plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
