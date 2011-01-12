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
# Outputs the issues to stdout, used with the CLI UI.<br/>
# All UIs must have a default report.
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2.1
#
class Stdout < Arachni::Report::Base

    #
    # @param [AuditStore]  audit_store
    # @param [Hash]   options    options passed to the report
    #
    def initialize( audit_store, options )
        @audit_store = audit_store
    end

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
        print_ok( @audit_store.issues.size.to_s + " issues were detected." )
        print_line

        @audit_store.issues.each {
            |issue|

            print_ok( issue.name )
            print_info( '~~~~~~~~~~~~~~~~~~~~' )

            print_info( 'ID Hash:  ' + issue._hash )
            print_info( 'Severity: ' + issue.severity ) if issue.severity
            print_info( 'URL:      ' + issue.url )
            print_info( 'Elements: ' + issue.elem )
            print_info( 'Variable: ' + issue.var )
            print_info( 'Description: ' )
            print_info( issue.description )

            if issue.cwe && !issue.cwe.empty?
                print_line
                print_info( "CWE: http://cwe.mitre.org/data/definitions/#{issue.cwe}.html" )
            end

            print_line
            print_info( 'Requires manual verification?: ' + issue.verification.to_s )
            print_line

            if( issue.references )
                print_info( 'References:' )
                issue.references.each{
                    |ref|
                    print_info( '  ' + ref[0] + ' - ' + ref[1] )
                }
            end

            print_info_variations( issue )

            print_line
        }

        sitemap  = @audit_store.sitemap.map{ |url| normalize( url ) }.uniq
        sitemap |= issue_urls = @audit_store.issues.map { |issue| issue.url }.uniq

        return if sitemap.size == 0

        print_info( 'URL health list.' )
        print_info( '--------------------' )

        print_line
        print_info( 'Color codes:' )
        print_ok( 'No issues' )
        print_error( 'Has issues' )
        print_line

        issue = 0
        sitemap.each {
            |url|

            next if !url

            if issue_urls.include?( url )
                print_error( url )
                issue += 1
            else
                print_ok( url )
            end
        }

        print_line

        total = sitemap.size
        safe  = total - issue
        issue_percentage = ( ( Float( issue ) / total ) * 100 ).round

        print_info( 'Total: ' + total.to_s )
        print_ok( 'Without issues: ' + safe.to_s )
        print_error( 'With issues: ' + issue.to_s + " ( #{issue_percentage.to_s}% )" )
        print_line

    end

    def self.info
        {
            :name           => 'Stdout',
            :description    => %q{Prints the results to standard output.},
            :author         => 'zapotek',
            :version        => '0.2.1',
        }
    end

    def normalize( url )
        query = URI( url ).query
        return url if !query

        url.gsub( '?' + query, '' )
    end


    def print_info_variations( issue )
        print_line
        print_status( 'Variations' )
        print_info( '----------' )
        issue.variations.each_with_index {
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
