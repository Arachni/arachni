=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'json'
class Arachni::Reports::HTML

#
# HTML formatter for the results of the Profiler plugin
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#
# @version 0.2.2
#
class PluginFormatters::Profiler < Arachni::Plugin::Formatter
    include Utils

    def run
        ERB.new( IO.read( File.dirname( __FILE__ ) + '/profiler/template.erb' ) ).result( binding )
    end

end
end
