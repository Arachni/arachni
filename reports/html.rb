=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'erb'
require 'base64'
require 'cgi'

module Arachni

module Reports

#
# Creates an HTML report of the audit.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class HTML < Arachni::Report::Base

    #
    # @param [AuditStore]  audit_store
    # @param [Hash]   options    options passed to the report
    #
    def initialize( audit_store, options )
        @audit_store   = audit_store
        @options       = options
    end

    #
    # Runs the HTML report.
    #
    def run( )

        print_line( )
        print_status( 'Creating HTML report...' )

        report = ERB.new( IO.read( @options['tpl'] ) )

        __prepare_data

        __save( @options['outfile'], report.result( binding ) )

        print_status( 'Saved in \'' + @options['outfile'] + '\'.' )
    end

    def self.info
        {
            :name           => 'HTML Report',
            :description    => %q{Exports a report as an HTML document.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptPath.new( 'tpl', [ false, 'Template to use.',
                    File.dirname( __FILE__ ) + '/html/default.erb' ] ),
                Arachni::OptString.new( 'outfile', [ false, 'Where to save the report.',
                    Time.now.to_s + '.html' ] ),
            ]
        }
    end

    private

    def __save( outfile, out )
        file = File.new( outfile, 'w' )
        file.write( out )
        file.close
    end

    def __prepare_data( )

        @graph_data = {
            :severities => {},
            :issues     => {},
            :elements   => {}
        }

        @audit_store.issues.each_with_index {
            |issue, i|

            @graph_data[:severities][issue.severity] ||= 0
            @graph_data[:severities][issue.severity] += 1

            @graph_data[:issues][issue.name] ||= 0
            @graph_data[:issues][issue.name] += 1

            @graph_data[:elements][issue.elem] ||= 0
            @graph_data[:elements][issue.elem] += 1

            issue.variations.each_with_index {
                |variation, j|

                if( variation['response'] && !variation['response'].empty? )
                    @audit_store.issues[i].variations[j]['escaped_response'] =
                        Base64.encode64( variation['response'] ).gsub( /\n/, '' )
                end

                response = {}
                if !variation['headers']['response'].is_a?( Hash )
                    variation['headers']['response'].split( "\r\n" ).each {
                        |line|
                        field, value = line.split( ':', 2 )
                        next if !value
                        response[field] = value
                    }
                end
                variation['headers']['response'] = response.dup

            }

        }

    end

end

end
end
