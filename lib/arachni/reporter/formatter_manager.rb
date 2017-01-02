=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Reporter

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class FormatterManager < Component::Manager
    def paths
        @paths_cache ||=
            Dir.glob( File.join( "#{@lib}", '*.rb' ) ).
                reject { |path| helper?( path ) }
    end
end

end
end
