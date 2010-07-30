=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end
require 'liquid'
require 'base64'

module Arachni

module Reports

#
# Creates an HTML report of the audit.
#
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: $Rev$
#
class HTML < Arachni::Report::Base

    # register us with the system
    include Arachni::Report::Registrar

    # get the output interface
    include Arachni::UI::Output

    #
    # @param [Array]  audit  the result of the audit
    # @param [Hash]   options    options passed to the report
    # @param [String]    outfile    where to save the report
    #
    def initialize( audit, options, outfile = nil )
        @audit     = audit
        @options   = options
        @outfile   = outfile + '.html'
        
        @tpl = File.dirname( __FILE__ ) + '/html/templates/index.tpl'
    end

    #
    # Use it to run your report.
    #
    def run( )

        print_line( )
        print_status( 'Creating HTML report...' )

        @template = Liquid::Template.parse( IO.read( @tpl ) )
        
        out = @template.render( __prepare_data( ) )
        
        __save( @outfile, out )

        print_status( 'Saved in \'' + @outfile + '\'.' )
    end

    def self.info
        {
            'Name'           => 'HTML Report',
            'Options'        => {
                'headers' =>
                    ['true/false (Default: true)', 'Include headers in the report?' ],
                'html_response' =>
                    [ 'true/false (Default: true)', 'Include the HTML response in the report?' ]
            },
            'Description'    => %q{Exports a report as an HTML document.},
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
        }
    end

    def __save( outfile, out )
        file = File.new( outfile, 'w' )
        file.write( out )
        file.close
    end

    def __prepare_data( )

        @audit['audit']['vulns'].each_with_index {
            |vuln, i|

            vuln['variations'].each_with_index {
                |variation, j|
                
                @audit['audit']['vulns'][i]['variations'][j]['escaped_response'] =
                    Base64.encode64( variation['response'] ).gsub( /\n/, '' )
                
                @audit['audit']['vulns'][i]['variations'][j].delete( 'response' )
            }        
        }
     
        @audit['date'] = Time.now.to_s
        @audit['opts'] = @options
        
        return @audit 
    end

end

end
end
