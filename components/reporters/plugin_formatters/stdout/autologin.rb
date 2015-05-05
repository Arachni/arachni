=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::Stdout

# Stdout formatter for the results of the AutoLogin plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::AutoLogin < Arachni::Plugin::Formatter

    def run
        print_ok results['message']

        return if !results['cookies']
        print_info 'Cookies set to:'
        results['cookies'].each_pair { |name, val| print_info "    * #{name} = #{val}" }
    end

end
end
