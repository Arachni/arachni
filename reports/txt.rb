=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end


module Arachni
module Reports    
    
#
# Creates a plain text report of the audit.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Text < Arachni::Report::Base
    
    # register us with the system
    include Arachni::Report::Registrar
    
    #
    # @param [AuditStore]  audit_store
    # @param [Hash]        options    options passed to the report
    # @param [String]      outfile    where to save the report
    #
    def initialize( audit_store, options = nil, outfile = nil )
        @audit_store = audit_store
        @outfile     = outfile + '.txt'
        
        # text buffer
        @__buffer = ''
    end
    
    def run( )
        
        print_line( )
        print_status( 'Creating text report...' )

        
        __buffer( 'Web Application Security Report - Arachni Framework' )
        __buffer
        __buffer( 'Report generated on: ' + Time.now.to_s )
        __buffer
        __buffer( 'Report false positives: ' + REPORT_FP )
        __buffer
        __buffer( 'System settings:' )
        __buffer( '---------------' )
        __buffer( 'Version:  ' + @audit_store.version )
        __buffer( 'Revision: '+ @audit_store.revision )
        __buffer( 'Audit started on:  ' + @audit_store.start_datetime )
        __buffer( 'Audit finished on: ' + @audit_store.finish_datetime )
        __buffer( 'Runtime: ' + @audit_store.delta_time )
        __buffer
        __buffer( 'URL: ' + @audit_store.options['url'] )
        __buffer( 'User agent: ' + @audit_store.options['user_agent'] )
        __buffer( 'Audited elements: ' )
        __buffer( '* Links' ) if @audit_store.options['audit_links']
        __buffer( '* Forms' ) if @audit_store.options['audit_forms']
        __buffer( '* Cookies' ) if @audit_store.options['audit_cookies']
        __buffer( '* Headers' ) if @audit_store.options['audit_headers']
        __buffer
        __buffer( 'Modules: ' + @audit_store.options['mods'].join( ', ' ) )
        __buffer( 'Filters: ' )
        
        if @audit_store.options['exclude']
            __buffer( "  Exclude:" )
            @audit_store.options['exclude'].each {
                |ex|
                __buffer( '    ' + ex )
            }
        end
        
        if @audit_store.options['include']
            __buffer( "  Include:" )
            @audit_store.options['include'].each {
                |inc|
                __buffer( "    " + inc )
            }
        end

        if @audit_store.options['redundant']
            __buffer( "  Redundant:" )
            @audit_store.options['redundant'].each {
                |red|
                __buffer( "    " + red )
            }
        end

        
        __buffer( 'Cookies: ' )
        @audit_store.options['redundant'].each {
            |cookie|
            __buffer( "#{cookie.name} = #{cookie.value}" )
        }
        
        __buffer
        __buffer( '===========================' )
        __buffer
        __buffer( @audit_store.vulns.size.to_s + " vulnerabilities were detected." )
        __buffer
        
        @audit_store.vulns.each {
            |vuln|
            
            __buffer( vuln.name )
            __buffer( '~~~~~~~~~~~~~~~~~~~~' )
            
            __buffer( 'URL:      ' + vuln.url )
            __buffer( 'Elements: ' + vuln.elem )
            __buffer( 'Variable: ' + vuln.var )
            __buffer( 'Description: ' )
            __buffer( vuln.description )
            __buffer
            __buffer( 'References:' )
            vuln.references.each{
                |ref|
                __buffer( '  ' + ref[0] + ' - ' + ref[1] )
            }
            
            __buffer_variations( vuln )
            
            __buffer
        }
        
        __buffer( "\n" )

        __buffer_write( )
        
        print_status( 'Saved in \'' + @outfile + '\'.' )
    end
    
    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            :name           => 'Text report',
            :description    => %q{Exports a report as a plain text file.},
            :author         => 'zapotek',
            :version        => '0.1',
        }
    end
    
    def __buffer_variations( vuln )
        __buffer
        __buffer( 'Variations' )
        __buffer( '----------' )
        vuln.variations.each_with_index {
            |var, i|
            __buffer( "Variation #{i+1}:" )
            __buffer( 'URL: ' + var['url'] )
            __buffer( 'ID:  ' + var['id'] )
            __buffer( 'Injected value:     ' + var['injected'] )
            __buffer( 'Regular expression: ' + var['regexp'] )
            __buffer( 'Matched string:     ' + var['regexp_match'] )
            
            __buffer
        }
    end
    
    def __buffer( str = '' )
        @__buffer += str + "\n"
    end
    
    def __buffer_write( )
        file = File.new( @outfile, 'w' )
        file.write( @__buffer )
        file.close
    end
    
end

end
end
