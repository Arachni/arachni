=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class LinkTemplate
module Capabilities

# Extends {Arachni::Element::Capabilities::Inputtable} with {LinkTemplate}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Inputtable
    include Arachni::Element::Capabilities::Inputtable

    INVALID_INPUT_DATA = [
        # Protocol URLs require a // which we can't preserve.
        '://'
    ]

    # @param    [String]    name
    #   Input name.
    #
    # @return   [Bool]
    #   `true` if the `name` can be found as a named capture in {#template},
    #   `false` otherwise.
    def valid_input_name?( name )
        return if !@template
        @template.names.include? name
    end

    # @param    [String]    data
    #   Input data.
    #
    # @return   [Bool]
    #   `true` if the `data` don't contain strings specified in
    #   #{INVALID_INPUT_DATA}, `false` otherwise.
    #
    # @see INVALID_INPUT_DATA
    def valid_input_data?( data )
        !INVALID_INPUT_DATA.find { |c| data.include? c }
    end

end

end
end
end
