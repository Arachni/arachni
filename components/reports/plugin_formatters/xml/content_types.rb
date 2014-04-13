=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::XML

# XML formatter for the results of the ContentTypes plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::ContentTypes < Arachni::Plugin::Formatter
    include Buffer

    def run
        results.each do |type, responses|
            start_content_type( type )

            responses.each do |res|
                start_tag 'response'

                simple_tag( 'url', res[:url] )
                simple_tag( 'method', res[:method] )

                if res[:parameters] && res[:method].downcase == 'post'
                    start_tag 'params'
                    res[:parameters].each { |name, value| add_param( name, value ) }
                    end_tag 'params'
                end

                end_tag 'response'
            end

            end_content_type
        end

        buffer
    end

    def start_content_type( type )
        append "<content_type name=\"#{type}\">"
    end

    def end_content_type
        append '</content_type>'
    end

end
end
