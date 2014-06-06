=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module HTTP
class Request

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
