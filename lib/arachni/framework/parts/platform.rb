=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Framework
module Parts

# Provides access to {Arachni::Platform} helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Platform

    # @return    [Array<Hash>]
    #   Information about all available platforms.
    def list_platforms
        platforms = Arachni::Platform::Manager.new
        platforms.valid.inject({}) do |h, platform|
            type = Arachni::Platform::Manager::TYPES[platforms.find_type( platform )]
            h[type] ||= {}
            h[type][platform] = platforms.fullname( platform )
            h
        end
    end

end

end
end
end
