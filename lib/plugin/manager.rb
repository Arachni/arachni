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

    def prep_opts( plugin_name, plugin, user_opts = {} )
        info = plugin.info
        return true if !info.include?( :options ) || info[:options].empty?

        options = { }
        errors = { }
        info[:options].each {
            |opt|

            name  = opt.name
            val   = user_opts[name]

            if( opt.empty_required_value?( val ) )
                errors[name] = {
                    :opt   => opt,
                    :value => val,
                    :type  => :empty_required_value
                }
            elsif( !opt.valid?( val ) )
                errors[name] = {
                    :opt   => opt,
                    :value => val,
                    :type  => :invalid
                }
            end

            val = !val.nil? ? val : opt.default
            options[name] = opt.normalize( val )
        }

        if( !errors.empty? )
            print_errors( plugin_name, errors )
        end

        return options
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

    private

    def print_errors( name, errors )

        print_line
        print_line

        print_error( "Invalid options for plugin: #{name}" )

        errors.each {
            |optname, error|

            val = error[:value].nil? ? '<empty>' : error[:value]

            if( error[:type] == :invalid )
                msg = "Invalid type"
            else
                msg = "Empty required value"
            end

            print_info( " *  #{msg}: #{optname} => #{val}" )
            print_info( " *  Expected type: #{error[:opt].type}" )

            print_line
        }

        exit
    end

    def load_from_path( path )
        return old_load_from_path( path )
    end

end
end
end
