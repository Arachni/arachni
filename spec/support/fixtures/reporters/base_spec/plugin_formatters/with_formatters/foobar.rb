=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::WithFormatters::PluginFormatters::Foobar < Arachni::Plugin::Formatter
    def run
        @results
    end
end
