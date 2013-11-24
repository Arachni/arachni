=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::Stdout

#
# Stdout formatter for the results of the FormDicattack plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::FormDicattack < Arachni::Plugin::Formatter

    def run
        print_info "Cracked credentials:"
        print_ok "    Username: '#{results[:username]}'"
        print_ok "    Password: '#{results[:password]}'"
    end

end

end
