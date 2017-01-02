=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::XML

# XML formatter for the results of the FormDicattack plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::FormDicattack < Arachni::Plugin::Formatter

    def run( xml )
        xml.username results['username']
        xml.password results['password']
    end

end
end
