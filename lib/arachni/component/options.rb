=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Component
module Options

    # {Component::Options} error namespace.
    #
    # All {Component::Options} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::Component::Error

        # Raised when a provided option is not valid.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class Invalid < Error
        end
    end

    lib = File.dirname( __FILE__ ) + '/options/'
    require lib + 'base'
    Dir.glob( lib + '*.rb' ).each { |p| require p }

end
end

end
