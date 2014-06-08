=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::WithFormatters < Arachni::Reporter::Base

    def run
        File.open( 'with_formatters', 'w' ) { |f| f.write( format_plugin_results ) }
    end

end
