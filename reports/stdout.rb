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
# Default report.
#
# Outputs the vulnerabilities to stdout, used with the CLI UI.<br/>
# All UIs must have a default report.
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
class Stdout < Arachni::Report::Base

    #
    # @param [AuditStore]  audit_store
    # @param [Hash]   options    options passed to the report
    # @param [String]    outfile    where to save the report
    #
    def initialize( audit_store, options = nil, outfile = nil )
        @audit_store = audit_store
    end

    #
    # REQUIRED
    #
    # Use it to run your report.
    #
    def run( )

        print_line( "\n" )
        print_line( "=" * 80 )
        print_line( "\n" )
        print_ok( 'Web Application Security Report - Arachni Framework' )
        print_line
        print_info( 'Report generated on: ' + Time.now.to_s )
        print_info( 'Report false positives: ' + REPORT_FP )
        print_line
        print_ok( 'System settings:' )
        print_info( '---------------' )
        print_info( 'Version:  ' + @audit_store.version )
        print_info( 'Revision: '+ @audit_store.revision )
        print_info( 'Audit started on:  ' + @audit_store.start_datetime )
        print_info( 'Audit finished on: ' + @audit_store.finish_datetime )
        print_info( 'Runtime: ' + @audit_store.delta_time )
        print_line
        print_info( 'URL: ' + @audit_store.options['url'] )
        print_info( 'User agent: ' + @audit_store.options['user_agent'] )
        print_line
        print_status( 'Audited elements: ' )
        print_info( '* Links' ) if @audit_store.options['audit_links']
        print_info( '* Forms' ) if @audit_store.options['audit_forms']
        print_info( '* Cookies' ) if @audit_store.options['audit_cookies']
        print_info( '* Headers' ) if @audit_store.options['audit_headers']
        print_line
        print_status( 'Modules: ' + @audit_store.options['mods'].join( ', ' ) )
        print_line
        print_status( 'Filters: ' )

        if @audit_store.options['exclude']
            print_info( "  Exclude:" )
            @audit_store.options['exclude'].each {
                |ex|
                print_info( '    ' + ex )
            }
        end

        if @audit_store.options['include']
            print_info( "  Include:" )
            @audit_store.options['include'].each {
                |inc|
                print_info( "    " + inc )
            }
        end

        if @audit_store.options['redundant']
            print_info( "  Redundant:" )
            @audit_store.options['redundant'].each {
                |red|
                print_info( "    " + red['regexp'] + ':' + red['count'].to_s )
            }
        end

        print_line
        print_status( 'Cookies: ' )
        if( @audit_store.options['cookies'] )
            @audit_store.options['cookies'].each {
                |cookie|
                print_info( "  #{cookie[0]} = #{cookie[1]}" )
            }
        end

        print_line
        print_info( '===========================' )
        print_line
        print_ok( @audit_store.vulns.size.to_s + " vulnerabilities were detected." )
        print_line

        @audit_store.vulns.each {
            |vuln|

            print_ok( vuln.name )
            print_info( '~~~~~~~~~~~~~~~~~~~~' )

            print_info( 'URL:      ' + vuln.url )
            print_info( 'Elements: ' + vuln.elem )
            print_info( 'Variable: ' + vuln.var )
            print_info( 'Description: ' )
            print_info( vuln.description )
            print_line
            print_info( 'Requires manual verification?: ' + vuln.verification.to_s )
            print_line
            print_info( 'References:' )
            vuln.references.each{
                |ref|
                print_info( '  ' + ref[0] + ' - ' + ref[1] )
            }

            print_info_variations( vuln )

            print_line
        }

        print_line( "\n" )

    end

    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            :name           => 'Stdout',
            :description    => %q{Prints the results to standard output.},
            :author         => 'zapotek',
            :version        => '0.2',
        }
    end

    def print_info_variations( vuln )
        print_line
        print_status( 'Variations' )
        print_info( '----------' )
        vuln.variations.each_with_index {
            |var, i|
            print_info( "Variation #{i+1}:" )
            print_info( 'URL: ' + var['url'] )
            print_info( 'ID:  ' + var['id'] )
            print_info( 'Injected value:     ' + var['injected'] )
            print_info( 'Regular expression: ' + var['regexp'].to_s )
            print_info( 'Matched string:     ' + var['regexp_match'] )

            print_line
        }
    end

end

end
end
