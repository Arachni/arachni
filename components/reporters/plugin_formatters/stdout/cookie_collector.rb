=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::Stdout

# Stdout formatter for the results of the CookieCollector plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::CookieCollector < Arachni::Plugin::Formatter

    def run
        results.each_with_index do |result, i|
            print_info "[#{(i + 1).to_s}] On #{result['time']}"
            print_info "URL: #{result['response']['url']}"

            print_info 'Cookies forced to: '
            result['cookies'].each_pair do |name, value|
                print_info "    #{name} => #{value}"
            end

            print_line
        end
    end

end
end
