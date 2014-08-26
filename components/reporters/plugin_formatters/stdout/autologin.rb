=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
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
