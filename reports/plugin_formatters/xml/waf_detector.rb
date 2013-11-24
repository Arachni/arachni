=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::XML

#
# XML formatter for the results of the WAF Detector plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::WAFDetector < Arachni::Plugin::Formatter
    include Buffer

    def run
        simple_tag( 'message', results[:msg] )
        simple_tag( 'code', results[:code] )
        buffer
    end

end
end
