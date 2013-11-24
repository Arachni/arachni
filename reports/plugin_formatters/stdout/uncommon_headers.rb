=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::Stdout

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
