=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::XML

# XML formatter for the results of the Uniformity plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::Uniformity < Arachni::Plugin::Formatter

    def run( xml )
        results.each do |digests|
            xml.digests digests.join( ' ' )
        end
    end

end
end
