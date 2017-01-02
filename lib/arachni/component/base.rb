=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
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
        include Arachni::Component::Output

        def fullname
            @fullname ||= info[:name]
        end

        def description
            @description ||= info[:description]
        end

        def author
            @author ||= info[:author]
        end

        def version
            @version ||= info[:version]
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
