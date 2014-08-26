=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
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
