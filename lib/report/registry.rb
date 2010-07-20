=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

module Arachni
module Report
    
#
# Arachni::Report::Registry class<br/>
# Holds and manages the registry of the reports
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: 0.1-planning
#
class Registry

    class << self
        attr_reader :registry
    end
    
    def initialize( lib )
        @lib = lib
        @@registry = []
        @available   = Hash.new
    end

    #
    # Loads and registers a report by it's filename, without the extension
    #
    # @param [String] name  the report to load
    #
    # @return [Arachni::Reports] the loaded reports
    #
    def rep_load( name )
        Registry.register( get_by_name( name ) )
    end
    
    #
    # Lists the loaded modules
    #
    # @return [Array<Arachni::Reports>]  contents of the @@module_registry
    #
    def ls_loaded( )
        @@registry
    end
    
    #
    # Gets a report by its filename, without the extension
    #
    # @param  [String]  name  the name of the report
    #
    # @return [Arachni::Reports]
    #
    def get_by_name( name )
        begin
            load( get_path_from_name( name ) )
        rescue Exception => e
            raise e
        end
    end

    #
    # Gets the path of the specified report
    #
    # @param  [String]  name  the name of the report
    #
    # @return [String]  the path of the report
    #
    def get_path_from_name( name )
        begin
            return ls_available( )[name]['path'].to_s
        rescue Exception => e
            raise( Arachni::Exceptions::ReportNotFound,
                'Uknown report \'' + name + '\'.' )
        end
    end

        
    #
    # Lists all available reports and puts them in a Hash
    #
    # @return [Hash<Hash<String, String>>]
    #
    def ls_available( )

        Dir.glob( @lib + '*.rb' ).each {
            |class_path|

            filename = class_path.gsub( Regexp.escape( @lib ) , '' )
            filename.gsub!( Regexp.new( '.rb' ) , '' )

            @available[filename] = Hash.new
            @available[filename]['path'] = class_path
        }
        @available
    end
    
    #
    # Class method
    #
    # Lists the loaded reports
    #
    # @return [Array<Arachni::Reports>]  the @@registry
    #
    def Registry.get_registry( )
        @@registry
    end
    
    #
    # Grabs the information of a report based on its ID
    # in the @@registry
    #
    # @param  [Integer] reg_id
    #
    # @return [Hash]  the info of the module
    #
    def info( reg_id )
        @@registry.each_with_index {
            |mod, i|
            if i == reg_id
                return mod.info
            end
        }
    end
    
    #
    # Registers a report with the framework
    #
    # Used by the Registrar *only*
    #
    def Registry.register( report )
        @@registry << report
        Registry.clean_up(  )
    end
    
    
    #
    # Class method
    #
    # Cleans the registry from boolean values
    # passed with the Arachni::Reports objects and updates it
    #
    # @return [Array<Arachni::Reports>]  the new @@registry
    #
    def Registry.clean_up( )

        clean_reg = []
        @@registry.each {
            |report|

            
            begin
                if report < Arachni::Report::Base
                    clean_reg << report
                end
            rescue Exception => e
            end

        }

        @@registry = clean_reg.uniq
    end

end

end
end
