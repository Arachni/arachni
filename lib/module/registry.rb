=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

module Arachni
module Module

#
# Arachni::Module::Registry class<br/>
# Holds and manages the registry of the modules
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: 0.1-planning
#
class Registry

    include Arachni::UI::Output
    
    #
    # Path to the module directory
    #
    # @return [String]
    #
    attr_reader :mod_lib

    #
    # Class variable
    #
    # Array of module objects
    #
    # @return [Array<Arachni::Module>]
    #
    class << self
        attr_reader :module_registry, :module_results, :module_storage
    end

    #
    # Initializes Arachni::Module::Registry with the module library
    #
    # @param [String] mod_lib path the the module directory
    #
    def initialize( mod_lib )
        
        @mod_lib = mod_lib
        
        @@module_registry = []
        @@module_results  = []
        @@module_storage  = []
            
        @available_mods   = Hash.new
    end

    #
    # Lists all available modules and puts them in a Hash
    #
    # @return [Hash<Hash<String, String>>]
    #
    def ls_available( )

        Dir.glob( @mod_lib + '*.rb' ).each {
            |class_path|

            filename = class_path.gsub( Regexp.escape( @mod_lib ) , '' )
            filename.gsub!( Regexp.new( '.rb' ) , '' )

            @available_mods[filename] = Hash.new
            @available_mods[filename]['path'] = class_path
        }
        @available_mods
    end

    #
    # Grabs the information of a module based on its ID
    # in the @@module_registry
    #
    # @param  [Integer] reg_id
    #
    # @return [Hash]  the info of the module
    #
    def mod_info( reg_id )
        @@module_registry.each_with_index {
            |mod, i|

            if i == reg_id
                info =  mod.info
                
                if( mod.methods.index( :deps ) ) 
                    info = info.merge( { 'Dependencies' => mod.deps } )
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
    def ls_loaded( )
        get_registry
    end

    #
    # Loads and registers a module by it's filename, without the extension
    # It also takes care of its dependencies.
    #
    # @param [String] mod_name  the module to load
    #
    # @return [Arachni::Module] the loaded modules
    #
    def mod_load( mod_name )
        
        Registry.register( get_module_by_name( mod_name ) )
        
        # grab the module we just registered
        mod = @@module_registry[-1]

         # if it doesn't have any dependencies we're done
        if( !mod.methods.index( :deps ) ) then return end
        
        # go through its dependencies and load them recursively
        mod.deps.each {
            |dep_mod|
                
            if ( !dep_mod ) then next end
            
            begin
                mod_load( dep_mod )
            rescue Exception => e
                print_error( "In '#{mod_name}' dependencies: " + e.to_s )
                exit 0
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
    def get_module_by_name( name )
        begin
            load( get_path_from_name( name ) )
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
    def get_path_from_name( name )
        begin
            ls_available( )[name]['path'].to_s
        rescue Exception => e
            raise 'Uknown module \'' + name + '\'.'
        end
    end

    #
    # Registers a module with the framework
    #
    # Used by the Registrar *only*
    #
    def Registry.register( mod )
        @@module_registry << mod
        Registry.clean_up(  )
    end

    #
    # Un-registers all modules
    #
    def Registry.clean( )
        @@module_registry    = []
    end
    
    #
    # Class method
    #
    # Lists the loaded modules
    #
    # @return [Array<Arachni::Module>]  the @@module_registry
    #
    def Registry.get_registry( )
        @@module_registry.uniq
    end

    #
    # Class method
    #
    # Registers module results with...well..us.
    #
    # @param    [Array]
    #
    def Registry.register_results( results )
        @@module_results += results
    end

    #
    # Class method
    #
    # Gets module results
    #
    # @param    [Array]
    #
    def Registry.get_results( )
        @@module_results
    end

    #
    # Lists the loaded modules
    #
    # @return [Array<Arachni::Module>]  the @@module_registry
    #
    def get_registry( )
        @@module_registry
    end

    #
    # Stores an object regulated by Registrar#add_storage
    # in @@module_storage
    #
    # @see Registrar#add_storage
    #
    # @param    [Object]    obj
    #
    def Registry.add_storage( obj )
        @@module_storage << obj
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
    def Registry.get_storage( key )
        @@module_storage.each {
            |item|
            if( item.keys[0] == key ) then return item[key] end
        }
    end
    
    #
    # Gets the entire storage array
    #
    # @return    [Array<Hash>]
    #
    def Registry.get_store( )
        @@module_storage
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
        @@module_registry.each {
            |mod|

            begin
                if mod < Arachni::Module::Base
                    clean_reg << mod
                end
            rescue Exception => e
            end

        }

        @@module_registry = clean_reg
    end

end
end
end