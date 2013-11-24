=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::XML

#
# XML formatter for the results of the CookieCollector plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::CookieCollector < Arachni::Plugin::Formatter
    include Buffer

    def run
        results.each_with_index do |result, i|
            start_tag 'response'

            simple_tag( 'time', result[:time].to_s )
            simple_tag( 'url', result[:res]['url'] )

            start_tag 'cookies'
            result[:cookies].each { |name, value| add_cookie( name, value ) }
            end_tag 'cookies'

            end_tag 'response'
        end

        buffer
    end

end
end
