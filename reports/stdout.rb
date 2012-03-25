=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
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
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.2.1
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

        @audit_store.issues.each_with_index {
            |issue, i|

            print_ok( "[#{i+1}] " + issue.name )
            print_info( '~~~~~~~~~~~~~~~~~~~~' )

            print_info( 'ID Hash:  ' + issue._hash )
            print_info( 'Severity: ' + issue.severity ) if issue.severity
            print_info( 'URL:      ' + issue.url )
            print_info( 'Element:  ' + issue.elem )
            print_info( 'Method:   ' + issue.method ) if issue.method
            print_info( 'Tags:     ' + issue.tags.join( ', ' ) ) if issue.tags.is_a?( Array )
            print_info( 'Variable: ' + issue.var ) if issue.var
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

        print_line
        print_ok( 'Plugin data:' )
        print_info( '---------------' )
        print_line

        # let the plugin formatters to their thing and print their results
        format_plugin_results( @audit_store.plugins )
    end

    def self.info
        {
            :name           => 'Stdout',
            :description    => %q{Prints the results to standard output.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.2.1',
        }
    end

    def print_info_variations( issue )
        print_line
        print_status( 'Variations' )
        print_info( '----------' )
        issue.variations.each_with_index {
            |var, i|
            print_info( "Variation #{i+1}:" )
            print_info( 'URL: ' + var['url'] )
            print_info( 'ID:  ' + var['id'].to_s ) if var['id']
            print_info( 'Injected value:     ' + var['injected'].to_s ) if var['injected']
            print_info( 'Regular expression: ' + var['regexp'].to_s ) if var['regexp']
            print_info( 'Matched string:     ' + var['regexp_match'].to_s ) if var['regexp_match']

            print_line
        }
    end

end

end
end
