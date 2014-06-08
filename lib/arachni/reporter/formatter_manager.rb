=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Reporter

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class FormatterManager < Component::Manager
    def paths
        Dir.glob( File.join( "#{@lib}", '*.rb' ) ).reject { |path| helper?( path ) }
    end
end

end
end
