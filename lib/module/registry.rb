=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
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
class Registry

    include Arachni::UI::Output

    #
    # Path to the module directory
    #
    # @return [String]
    #
    attr_reader :lib

    class << self

        #
        # Class variable
        #
        # Array of module objects
        #
        # @return [Array<Module>]
        #
        attr_reader :registry

        #
        # Class variable
        #
        # Array of {Vulnerability} instances discovered by modules
        #
        # @return [Array<Vulnerability>]
        #
        attr_reader :results

        #
        # Class variable
        #
        # Array of module data
        #
        # @return [Array<Hash>]
        #
        attr_reader :storage

    end

    #
    # Initializes Arachni::Module::Registry with the module library
    #
    # @param [String] lib path the the module directory
    #
    def initialize( opts )

        @lib = opts.dir['modules']

        @@registry = []
        @@results  = []
        @@storage  = Hash.new

        @available  = Hash.new
    end

    #
    # Lists all available modules and puts them in a Hash
    #
    # @return [Hash<Hash<String, String>>]
    #
    def available( )

        (recon | audit).each {
            |class_path|

            filename = class_path.gsub( Regexp.new( @lib ) , '' )
            filename = filename.gsub( /(recon|audit)\// , '' )
            filename.gsub!( Regexp.new( '.rb' ) , '' )

            @available[filename] = Hash.new
            @available[filename]['path'] = class_path
        }

        return @available
    end

    def recon
      by_type( "recon" )
    end

    def audit
      by_type( "audit" )
    end

    def by_type( type )
        Dir.glob( @lib + "#{type}/" + '*.rb' )
    end

    #
    # Grabs the information of a module based on its ID
    # in the @@module_registry
    #
    # @param  [Integer] reg_id
    #
    # @return [Hash]  the info of the module
    #
    def info( reg_id )
        @@registry.each_with_index {
            |mod, i|

            if i == reg_id
                info =  mod.info

                if( mod.methods.index( :deps ) )
                    info = info.merge( { :dependencies => mod.deps } )
                end

                return info
            end
        }
    end

    #
    # Lists the loaded modules
    #
    # @return [Array<Arachni::Module>]  contents of the @@module_registry
    #
    def loaded( )
        return registry
    end

    #
    # Loads modules
    #
    # @param [Array]  mods  Array of modules to load
    #
    def load( modules )

        final   = []
        modules = [modules]
        #
        # Check the validity of user provided module names
        #
        parse_mods( modules.flatten ).each {
            |mod_name|

            # if the mod name is '*' load all modules
            # and replace it with the actual module names
            if( mod_name == '*' )

                available(  ).keys.each {
                    |mod|
                    final << mod
                    _load( mod )
                }

            end

            final << mod_name
            _load( mod_name )
        }

        return final
    end

    #
    # Registers a module with the framework
    #
    # Used by the Registrar *only*
    #
    def Registry.register( mod )
        @@registry << mod
        Registry.clean_up(  )
    end

    #
    # Class method
    #
    # Lists the loaded modules
    #
    # @return [Array<Arachni::Module>]  the @@module_registry
    #
    def Registry.registry( )
        @@registry.uniq
    end

    #
    # Class method
    #
    # Registers module results with...well..us.
    #
    # @param    [Array]
    #
    def Registry.register_results( results )
        @@results |= results
    end

    #
    # Class method
    #
    # Gets module results
    #
    # @param    [Array]
    #
    def Registry.results( )
        @@results
    end

    def results
        @@results
    end

    def clear
        @@registry.clear
    end

    #
    # Lists the loaded modules
    #
    # @return [Array<Arachni::Module>]  the @@module_registry
    #
    def registry( )
        Registry.registry( )
    end

    #
    # Stores an object regulated by {Registrar#add_storage}
    # in @@module_storage
    #
    # @see Registrar#add_storage
    #
    # @param    [Object]    obj
    #
    def Registry.add_storage( obj )
        @@module_storage.merge( obj )
    end

    #
    # Gets data from storage by key,
    # regulated by Registrar#get_storage
    #
    # @see Registrar#add_storage
    #
    # @param    [Object]    key
    #
    # @return    [Object]    the data under key
    #
    def Registry.storage( key = nil )
        return @@storage if !key

        @@storage.each {
            |item|
            if( item.keys[0] == key ) then return item[key] end
        }
    end

    #
    # Class method
    #
    # Cleans the registry from boolean values
    # passed with the Arachni::Module::Base objects and updates it
    #
    # @return [Array<Arachni::Module>]  the new @@module_registry
    #
    def Registry.clean_up( )

        clean_reg = []
        @@registry.each {
            |mod|

            begin
                if mod < Arachni::Module::Base
                    clean_reg << mod
                end
            rescue Exception => e
            end

        }

        @@registry = clean_reg
    end

    private

    def parse_mods( mods )

        unload = []
        load   = []

        mods.each {
            |mod|
            if mod[0] == '-'
                mod[0] = ''
                unload << mod
            end
        }

        if( !mods.include?( "*" ) )

            avail_mods  = available(  )

            mods.each {
                |mod_name|
                if( !avail_mods[mod_name] )
                      raise( Arachni::Exceptions::ModNotFound,
                          "Error: Module #{mod_name} wasn't found." )
                end
            }

            # recon modules should be loaded before audit ones
            # and ls_available() honors that
            avail_mods.map {
                |mod|
                load << mod[0] if mods.include?( mod[0] )
            }
        else
            available(  ).map {
                |mod|
                load << mod[0]
            }
        end

        return load - unload
    end


    #
    # Loads and registers a module by it's filename, without the extension
    # It also takes care of its dependencies.
    #
    # @param [String] mod_name  the module to load
    #
    # @return [Arachni::Module] the loaded modules
    #
    def _load( mod_name )

        Registry.register( by_name( mod_name ) )

        # grab the module we just registered
        mod = @@registry[-1]

         # if it doesn't have any dependencies we're done
        if( !mod.methods.index( :deps ) ) then return end

        # go through its dependencies and load them recursively
        mod.deps.each {
            |dep_mod|

            if ( !dep_mod ) then next end

            begin
                load( dep_mod )
            rescue Exception => e
                raise( Arachni::Exceptions::DepModNotFound,
                    "In '#{mod_name}' dependencies: " + e.to_s )
            end

        }

    end

    #
    # Gets a module by its filename, without the extension
    #
    # @param  [String]  name  the name of the module
    #
    # @return [Arachni::Module]
    #
    def by_name( name )
        begin
            ::Kernel::load( path_from_name( name ) )
        rescue Exception => e
            raise e
        end
    end

    #
    # Gets the path of the specified module
    #
    # @param  [String]  name  the name of the module
    #
    # @return [String]  the path of the module
    #
    def path_from_name( name )
        begin
            available( )[name]['path'].to_s
        rescue Exception => e
            raise( Arachni::Exceptions::ModNotFound,
                "Module '#{mod_name}' not found." )
        end
    end


end
end
end
