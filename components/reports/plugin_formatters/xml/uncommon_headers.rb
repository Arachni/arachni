=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::XML

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::UncommonHeaders < Arachni::Plugin::Formatter
    include Buffer

    def run
        results.each do |url, headers|
            append "<url value='#{escape( url )}'>"

            headers.each do |name, value|
                add_header name, value
            end

            end_tag 'url'
        end

        buffer
    end

end
end
