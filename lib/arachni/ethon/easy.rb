=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Ethon
class Easy
module Callbacks
    def debug_callback
        @debug_callback ||= proc do |handle, type, data, size, udata|
            message = data.read_string( size )
            @debug_info.add type, message
            # print message unless [:data_in, :data_out].include?(type)
            0
        end
    end
end
end
end
