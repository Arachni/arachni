=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
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
