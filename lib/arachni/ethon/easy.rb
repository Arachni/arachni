=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
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
