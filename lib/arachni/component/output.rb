=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Component

# Provides output functionality to the checks via {Arachni::UI::Output},
# prefixing the check name to the output message.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Output
    include UI::Output

    def depersonalize_output
        @depersonalize_output = true
    end

    def depersonalize_output?
        @depersonalize_output
    end

    def intercept_print_message( message )
        depersonalize_output? ? message : "#{self.class.fullname}: #{message}"
    end

end
end
end
