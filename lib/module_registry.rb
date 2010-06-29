=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end
module Arachni

#
# Arachni::ModuleRegistry class<br/>
# Holds and manages the registry of the modules
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: 0.1-planning
#
class ModuleRegistry
  
  #
  # Path to the module directory
  #
  # @return [String]
  #
  attr_reader :mod_lib
  
  #
  # Class variable
  # Array of module objects
  #
  # @return [Array<Arachni::Module>]
  #
  class << self; attr_accessor :module_registry end
  
  #
  # Initializes Arachni::ModuleRegistry with the module library
  #
  # @param [String] mod_lib path the the module directory
  #
  def initialize( mod_lib )
    @mod_lib = mod_lib
    @@module_registry = []
    @available_mods = Hash.new
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
#      @available_mods[filename]['info'] = get_module_by_name( class_path )
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
        return mod.info
      end
    }
  end
  
  #
  # Grabs the information of a module based on its ID
  # in the @@module_registry and returns it as a string
  #
  # @param  [Integer] reg_id
  #
  # @return [String]  the info of the module
  #
  def mod_info_s( reg_id )
    info = mod_info( reg_id )
    puts "Name:\t\t" + info["Name"].strip
    puts "Description:\t" + info["Description"].strip
    puts "Author:\t\t" + info["Author"].strip
    puts "Version:\t" + info["Version"].strip
    puts "References:\t" + info["References"].to_s
    puts "Targets:\t" + info["Targets"].to_s
    
  end
  
  #
  # Lists the loaded modules
  #
  # @return [Array<Arachni::Module>]  contents of the @@module_registry
  #
  def ls_loaded( )
    get_registers
  end
  
  #
  # Loads and registers a module by it's filename, without the extension
  #
  # @param [String] mod_name  the module to load
  #
  # @return [Arachni::Module] the loaded modules
  #
  def mod_load( mod_name )
    ModuleRegistry.register( get_module_by_name( mod_name ) )
  end
  
  #
  # Gets a module by its filename, without the extension
  #
  # @param  [String]  name  the name of the module
  #
  # @return [Arachni::Module]
  #
  def get_module_by_name( name )
    load( get_path_from_name( name ) )
  end

  #
  # Gets the path of the specified module
  #
  # @param  [String]  name  the name of the module
  #
  # @return [String]  the path of the module
  #
  def get_path_from_name( name )
    ls_available( )[name]['path'].to_s
  end

  #
  # Gets the path of the specified module
  #
  # @param  [String]  name  the name of the module
  #
  # @return [String]  the path of the module
  #
  def ModuleRegistry.register( mod )
    @@module_registry << mod
    ModuleRegistry.clean_up(  )
  end

  #
  # Class method
  # Lists the loaded modules
  #
  # @return [Array<Arachni::Module>]  the @@module_registry
  #
  def ModuleRegistry.get_registers( )
    @@module_registry
  end
  
  #
  # Lists the loaded modules
  #
  # @return [Array<Arachni::Module>]  the @@module_registry
  #
  def get_registers( )
    @@module_registry
  end
  
  #
  # Class method
  # Cleans the registry from boolean values
  # passed with the Arachni::Module objects and updates it
  #
  # @return [Array<Arachni::Module>]  the new @@module_registry
  #
  def ModuleRegistry.clean_up( )
    
    clean_reg = [] 
    @@module_registry.each {
      |mod|
      
      begin
        if mod < Arachni::Module
          clean_reg << mod
        end
      rescue Exception => e
      end
      
    }
    
    @@module_registry = clean_reg 
  end
  
end
end
