=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::XML

# XML formatter for the results of the AutoLogin plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::AutoLogin < Arachni::Plugin::Formatter
    include Buffer

    def run
        simple_tag( 'message', results[:message] )
        simple_tag( 'status', results[:status].to_s )

        start_tag 'cookies'
        if results[:cookies]
            results[:cookies].each { |name, value| add_cookie( name, value ) }
        end
        end_tag 'cookies'

        buffer
    end

end
end
