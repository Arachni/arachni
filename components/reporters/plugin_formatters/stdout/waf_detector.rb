=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Reporters::Stdout

# Stdout formatter for the results of the WAFDetector plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::WAFDetector < Arachni::Plugin::Formatter

    def run
        print_ok results['message']
    end

end
end
