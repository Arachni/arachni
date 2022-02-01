=begin
    Copyright 2010-2022 Ecsypno <http://www.ecsypno.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class Header
module Capabilities

# Extends {Arachni::Element::Capabilities::Inputtable} with {Header}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Inputtable
    include Arachni::Element::Capabilities::Inputtable

    INVALID_INPUT_DATA = [ "\0" ]

    def valid_input_data?( data )
        !INVALID_INPUT_DATA.find { |c| data.include? c }
    end

end
end
end
end
