=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module HTTP
class Request

# Determines the {Scope scope} status of {Request}s.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Scope < Message::Scope

    # {Scope} error namespace.
    #
    # All {Scope} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Message::Scope::Error
    end

end

end
end
end
