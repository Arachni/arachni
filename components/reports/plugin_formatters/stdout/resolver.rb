=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::Stdout

#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::Resolver < Arachni::Plugin::Formatter

    def run
        results.each { |hostname, ipaddress| print_info( hostname.to_s + ': ' + ipaddress.to_s ) }
    end

end
end
