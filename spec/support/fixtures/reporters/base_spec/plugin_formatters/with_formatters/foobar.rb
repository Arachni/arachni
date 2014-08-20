=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Reporters::WithFormatters::PluginFormatters::Foobar < Arachni::Plugin::Formatter
    def run
        @results
    end
end
