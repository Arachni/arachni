=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::XML

# XML formatter for the results of the FormDicattack plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::FormDicattack < Arachni::Plugin::Formatter

    def run( xml )
        xml.username results['username']
        xml.password results['password']
    end

end
end
