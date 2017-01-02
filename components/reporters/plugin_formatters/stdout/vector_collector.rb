=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::Stdout

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::VectorCollector < Arachni::Plugin::Formatter

    def run
        results.each do |url, elements|
            print_status url
            print_status '-' * 80

            elements.each do |element|
                print_info "#{element['type']} pointing to #{element['action']}"

                if (element['inputs'] || {}).any?
                    element['inputs'].each do |name, value|
                        print_info "    #{name.inspect} => #{value.inspect}"
                    end
                end

                if element['source']
                    print_info element['source']
                end

                print_line
            end

            print_line
        end
    end

end
end
