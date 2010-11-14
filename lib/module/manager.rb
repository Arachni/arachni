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
# Arachni::Module::Manager class
#
# Holds and manages the modules and their results.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Manager < Arachni::ComponentManager

    include Arachni::UI::Output

    #
    # @param    [Arachni::Options]  opts
    #
    def initialize( opts )
        super( opts.dir['modules'], Arachni::Modules )
        @opts = opts
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
        Arachni::Modules.reset
    end

end
end
end
