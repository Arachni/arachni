=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module HTTP
class Message

# Determines the {Scope scope} status of {Message}s.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Scope < URI::Scope

    # {Scope} error namespace.
    #
    # All {Scope} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < URI::Scope::Error
    end

    # @param    [Arachni::HTTP::Message]  message
    def initialize( message )
        super message.parsed_url
    end

end

end
end
end
