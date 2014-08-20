=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Reporters::Stdout

#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::UncommonHeaders < Arachni::Plugin::Formatter

    def run
        results.each do |url, headers|
            print_status url

            headers.each do |name, value|
                print_info "#{name}: #{value}"
            end

            print_line
        end
    end

end
end
