=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
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
