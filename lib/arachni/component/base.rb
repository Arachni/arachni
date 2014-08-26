=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni

lib = Options.paths.lib
require lib + 'component/output'
require lib + 'component/utilities'

module Component

# Base check class to be extended by all components.
#
# Defines basic structure and provides utilities.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @abstract
class Base
    include Arachni # I hate having to keep typing this all the time.
    include Component::Output

    include Component::Utilities
    extend  Component::Utilities

    def shortname
        self.class.shortname
    end

    class <<self
        def fullname
            info[:name]
        end

        def description
            info[:description]
        end

        def author
            info[:author]
        end

        def version
            info[:version]
        end

        def shortname=( shortname )
            @shortname = shortname
        end

        def shortname
            @shortname
        end
    end

end
end
end
