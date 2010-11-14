=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

#
# The namespace under which all plugins exist
#
module Plugins

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

module Plugin

#
# Holds and manages the plugins.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Manager < Arachni::ComponentManager

    include Arachni::UI::Output

    #
    # @param    [Arachni::Options]    opts
    #
    def initialize( framework )
        super( framework.opts.dir['pwd'] + 'plugins', Arachni::Plugins )
        @framework = framework
    end

    def run
        each {
            |name, plugin|
            plugin.new( @framework, {} ).run
        }
    end

end
end
end
