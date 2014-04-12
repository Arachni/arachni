=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::Stdout

# Stdout formatter for the results of the AutoLogin plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::AutoLogin < Arachni::Plugin::Formatter

    def run
        print_ok results[:message]

        return if !results[:cookies]
        print_info 'Cookies set to:'
        results[:cookies].each_pair { |name, val| print_info "    * #{name} = #{val}" }
    end

end
end
