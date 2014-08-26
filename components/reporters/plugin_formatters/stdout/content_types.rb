=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Reporters::Stdout

# Stdout formatter for the results of the ContentTypes plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::ContentTypes < Arachni::Plugin::Formatter

    def run
        results.each do |type, responses|
            print_ok type

            responses.each do |res|
                print_status "    URL:    #{res['url']}"
                print_info   "    Method: #{res['method']}"

                if res['parameters'] && res['method'].downcase == 'post'
                    print_info '    Parameters:'
                    res['parameters'].each do |k, v|
                        print_info "        #{k} => #{v}"
                    end
                end

                print_line
            end

            print_line
        end
    end

end
end
