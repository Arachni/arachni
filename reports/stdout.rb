=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

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
            print_info( 'Element:  ' + issue.elem )
            print_info( 'Method:   ' + issue.method ) if issue.method
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

        print_plugin_results

    end

    def self.info
        {
            :name           => 'Stdout',
            :description    => %q{Prints the results to standard output.},
            :author         => 'zapotek',
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
            print_info( 'ID:  ' + var['id'] )
            print_info( 'Injected value:     ' + var['injected'] )
            print_info( 'Regular expression: ' + var['regexp'].to_s )
            print_info( 'Matched string:     ' + var['regexp_match'] )

            print_line
        }
    end

    def print_plugin_results
        return if @audit_store.plugins.empty?

        print_line
        print_ok( 'Plugin data:' )
        print_info( '---------------' )
        print_line

        print_cookie_collector
        print_form_dicattack
        print_http_dicattack
        print_healthmap
    end

    def print_healthmap
        healthmap = @audit_store.plugins['healthmap']
        return if !healthmap || healthmap[:results].empty?

        print_info( 'URL health list.' )
        print_info( '--------------------' )

        print_line
        print_info( 'Color codes:' )
        print_ok( 'No issues' )
        print_error( 'Has issues' )
        print_line

        healthmap[:results][:map].each {
            |i|

            state = i.keys[0]
            url   = i.values[0]

            if state == :unsafe
                print_error( url )
            else
                print_ok( url )
            end
        }

        print_line

        print_info( 'Total: ' + healthmap[:results][:total].to_s )
        print_ok( 'Without issues: ' + healthmap[:results][:safe].to_s )
        print_error( 'With issues: ' + healthmap[:results][:unsafe].to_s +
            " ( #{healthmap[:results][:issue_percentage].to_s}% )" )

        print_line

    end

    def print_cookie_collector
        cookie_collector = @audit_store.plugins['cookie_collector']
        return if !cookie_collector || cookie_collector[:results].empty?

        print_status( 'Cookie collector' )
        print_info( '~~~~~~~~~~~~~~~~~~' )

        print_info( 'Description: ' + cookie_collector[:description] )
        print_line

        cookie_collector[:results].each_with_index {
            |result, i|

            print_info( "[#{(i + 1).to_s}] On #{result[:time]}" )
            print_info( "URL: " + result[:res]['effective_url'] )
            print_info( 'Cookies forced to: ' )
            result[:cookies].each_pair{
                |name, value|
                print_info( "    #{name} => #{value}" )
            }
            print_line
        }

        print_line

    end

    def print_form_dicattack
        form_dicattack = @audit_store.plugins['form_dicattack']
        return if !form_dicattack || form_dicattack[:results].empty?

        print_status( 'Form dictionary attacker' )
        print_info( '~~~~~~~~~~~~~~~~~~~~~~~~~~' )

        print_info( 'Description: ' + form_dicattack[:description] )
        print_line
        print_info( "Cracked credentials:" )
        print_ok( '    Username: ' + form_dicattack[:results][:username] )
        print_ok( '    Password: ' + form_dicattack[:results][:password] )

        print_line
    end

    def print_http_dicattack
        http_dicattack = @audit_store.plugins['http_dicattack']
        return if !http_dicattack || http_dicattack[:results].empty?

        print_status( 'HTTP dictionary attacker' )
        print_info( '~~~~~~~~~~~~~~~~~~~~~~~~~~' )

        print_info( 'Description: ' + http_dicattack[:description] )
        print_line
        print_info( "Cracked credentials:" )
        print_ok( '    Username: ' + http_dicattack[:results][:username] )
        print_ok( '    Password: ' + http_dicattack[:results][:password] )

        print_line

    end


end

end
end
