=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::Stdout

#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
