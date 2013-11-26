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

    def intercept_print_message( message )
        "#{self.class.fullname}: #{message}"
    end

end
end
end
