=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Parser
module Nodes
class Element
module WithAttributes

class Attributes < Hash

    def []( name )
        super name.to_s.downcase
    end

    def []=( name, value )
        super name.to_s.downcase.freeze, value.freeze
    end

end

end
end
end
end
end
