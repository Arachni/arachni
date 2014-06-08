=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::XML

#
# XML formatter for the results of the HTTPDicattack plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::HTTPDicattack < Arachni::Plugin::Formatter
    include Buffer

    def run
        add_credentials( results[:username], results[:password] )
        buffer
    end

end
end
