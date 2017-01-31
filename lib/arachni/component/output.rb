=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Component

# Provides output functionality to the checks via {Arachni::UI::Output},
# prefixing the check name to the output message.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Output
    include UI::Output

    def depersonalize_output
        @depersonalize_output = true
    end

    def depersonalize_output?
        @depersonalize_output
    end

    def intercept_print_message( message )
        if self.class == Class
            fullname = self.fullname
        else
            fullname = self.class.fullname
        end

        depersonalize_output? ? message : "#{fullname}: #{message}"
    end

end
end
end
