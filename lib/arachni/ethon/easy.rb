=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Ethon
class Easy
module Callbacks
    def debug_callback
        @debug_callback ||= proc do |handle, type, data, size, udata|
            # We only care about these so that we can have access to raw
            # HTTP request traffic for reporting/debugging purposes.
            next if type != :header_out && type != :data_out

            message = data.read_string( size )
            @debug_info.add type, message
            0
        end
    end
end
end
end
