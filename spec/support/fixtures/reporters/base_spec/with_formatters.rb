=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Reporters::WithFormatters < Arachni::Reporter::Base

    def run
        File.open( 'with_formatters', 'w' ) { |f| f.write( format_plugin_results ) }
    end

end
