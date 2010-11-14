=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

#
# The namespace under which all modules exist
#
module Modules

    #
    # Resets the namespace unloading all module classes
    #
    def self.reset
        constants.each {
            |const|
            remove_const( const )
        }
    end
end

module Module

#
# Arachni::Module::Registry class
#
# Holds and manages the registry of the modules,
# their results and their shared datastore.
#
# It also provides methods for getting modules' info, listing available modules etc.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.3
#
class Manager < Arachni::ComponentManager

    include Arachni::UI::Output

    #
    # Initializes Arachni::Module::Registry with the module library
    #
    # @param [String] lib path the the module directory
    #
    def initialize( opts )
        super( opts.dir['reports'], Arachni::Modules )
        @opts = opts
        @lib  = opts.dir['modules']

        @@results  = []
    end

    #
    # Class method
    #
    # Registers module results with...well..us.
    #
    # @param    [Array]
    #
    def self.register_results( results )
        @@results |= results
    end

    #
    # Class method
    #
    # Gets module results
    #
    # @param    [Array]
    #
    def self.results( )
        @@results
    end

    def results
        @@results
    end

    def self.reset
        @@results.clear
        self.clear
        Arachni::Modules.reset
    end

end
end
end
