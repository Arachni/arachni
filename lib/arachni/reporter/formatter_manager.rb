=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
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
