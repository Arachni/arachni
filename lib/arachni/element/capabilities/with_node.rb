=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'with_source'

module Arachni
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module WithNode
    include WithSource

    # @return [Nokogiri::XML::Element]
    def node
        return if !@source
        Arachni::Parser.parse_fragment( @source.dup )
    end

end

end
end
