=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Most options are pretty much rip offs of Metasploit's
# (/lib/msf/core/option_container.rb)
#

module Arachni
module Component
module Options

    #
    # {Component::Options} error namespace.
    #
    # All {Component::Options} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    #
    class Error < Arachni::Component::Error

        #
        # Raised when a provided option is not valid.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        #
        class Invalid < Error
        end
    end

    lib = File.dirname( __FILE__ ) + '/options/'
    require lib + 'base'
    Dir.glob( lib + '*.rb' ).each { |p| require p }

end
end

    # Compat hack, makes options accessible as Arachni::Opt<type>
    Component::Options.constants.each do |sym|
        const_set( ('Opt' + sym.to_s).to_sym, Component::Options.const_get( sym ) )
    end

end
