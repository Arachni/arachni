=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::XML

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::UncommonHeaders < Arachni::Plugin::Formatter

    def run( xml )
        results.each do |url, headers|
            xml.entry {
                xml.url url

                xml.headers {
                    headers.each do |name, value|
                        xml.header name: name, value: value
                    end
                }
            }
        end
    end

end
end
