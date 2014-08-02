=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
module HTTP
class Request

# Determines the {Scope scope} status of {Request}s.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Scope < Message::Scope

    # {Scope} error namespace.
    #
    # All {Scope} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Message::Scope::Error
    end

end

end
end
end
