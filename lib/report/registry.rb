=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Report
    
#
# Arachni::Report::Registry class
#    
# Holds and manages the registry of the reports.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr> <br/>
# @version: 0.1.3
#
class Registry

    class << self
        attr_reader :registry
    end

    # the extension of the Arachni Framework Report files
    REPORT_EXT   = '.afr'

    def initialize( opts )
        
        @opts = opts
        @lib  = @opts.dir['reports']
        
        @@registry = []
        @available   = Hash.new
    end

    #
    # Takes care of report execution
    #
    # @see AuditStore
    #
    # @param  [AuditStore]  audit_store
    #
    def run( audit_store )
        
        loaded.each_with_index {
            |report, i|

            # if the user hasn't selected a filename for the report
            # choose one for him
            if( !@opts.repsave || @opts.repsave.size == 0 )
                @opts.repsave =
                    URI.parse( audit_store.options['url'] ).host +
                        '-' + Time.now.to_s
            end
            
            
            new_rep = report.new( audit_store.clone, @opts.repopts,
                            @opts.repsave + REPORT_EXT )
            
            new_rep.run( )
        }
    end


    #
    # Loads and registers a report by it's filename, without the extension
    #
    # @param [String] name  the report to load
    #
    # @return [Arachni::Reports] the loaded reports
    #
    def load( name )
        Registry.register( by_name( name ) )
    end
    
    #
    # Lists the loaded modules
    #
    # @return [Array<Arachni::Reports>]  contents of the @@module_registry
    #
    def loaded( )
        Registry.registry( )
    end
    
    #
    # Gets a report by its filename, without the extension
    #
    # @param  [String]  name  the name of the report
    #
    # @return [Arachni::Reports]
    #
    def by_name( name )
        begin
            ::Kernel::load( path_from_name( name ) )
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
    def path_from_name( name )
        begin
            return available( )[name]['path'].to_s
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
    def available( )

        Dir.glob( @lib + '*.rb' ).each {
            |class_path|

            filename = class_path.gsub( Regexp.new( @lib ) , '' )
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
    def Registry.registry( )
        @@registry.uniq
    end
    
    #
    # Class method
    #
    # Empties the report registry
    #
    # @return [Array<Arachni::Reports>]  the @@registry
    #
    def Registry.clean( )
        @@registry = []
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

        @@registry = clean_reg.uniq.flatten
    end

    def extension
        return REPORT_EXT
    end

end

end
end
