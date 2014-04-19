=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::Stdout

# Stdout formatter for the results of the WAFDetector plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::WAFDetector < Arachni::Plugin::Formatter

    def run
        print_ok results['message']
    end

end
end
