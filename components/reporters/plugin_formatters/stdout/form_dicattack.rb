=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::Stdout

# Stdout formatter for the results of the FormDicattack plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::FormDicattack < Arachni::Plugin::Formatter

    def run
        print_info 'Cracked credentials:'
        print_ok "    Username: '#{results['username']}'"
        print_ok "    Password: '#{results['password']}'"
    end

end

end
