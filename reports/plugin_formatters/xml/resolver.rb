=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::XML

#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::Resolver < Arachni::Plugin::Formatter
    include Buffer

    def run
        results.each do |hostname, ipaddress|
            append "<hostname value='#{hostname}' ipaddress='#{ipaddress}' />"
        end
        buffer
    end

end
end
