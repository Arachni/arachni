=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class Cookie
module Capabilities

# Extends {Arachni::Element::Capabilities::Inputtable} with {Cookie}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Inputtable
    include Arachni::Element::Capabilities::Inputtable

    # @example
    #    p c = Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff' ).first
    #    #=> ["session=stuffstuffstuff"]
    #
    #    p c.inputs
    #    #=> {"session"=>"stuffstuffstuff"}
    #
    #    p c.inputs = { 'new-name' => 'new-value' }
    #    #=> {"new-name"=>"new-value"}
    #
    #    p c
    #    #=> new-name=new-value
    #
    # @param    [Hash]  inputs
    #   Sets inputs.
    def inputs=( inputs )
        k = inputs.keys.first.to_s
        v = inputs.values.first.to_s

        @data[:name]  = k
        @data[:value] = v

        if k.to_s.empty?
            super( {} )
        else
            super( { k => v } )
        end
    end

end

end
end
end
