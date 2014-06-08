=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::Stdout

# Stdout formatter for the results of the HTTPDicattack plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::HTTPDicattack < Arachni::Plugin::Formatter

    def run
        print_info 'Cracked credentials:'
        print_ok "    Username: '#{results['username']}'"
        print_ok "    Password: '#{results['password']}'"
    end

end

end
