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

    alias old_load_from_path load_from_path

    #
    # @param    [Arachni::Options]    opts
    #
    def initialize( framework )
        super( framework.opts.dir['plugins'], Arachni::Plugins )
        @framework = framework
    end

    def run
        each {
            |name, plugin|

            opts = @framework.opts.plugins[name]

            plugin_new = plugin.new( @framework, prep_opts( name, plugin, opts ) )
            plugin_new.prepare
            plugin_new.run
            plugin_new.clean_up
        }
    end


    def load_from_path( path )
        return old_load_from_path( path )
    end

end
end
end
