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
# @version: $Rev: 198 $
#
class HTML < Arachni::Report::Base

    # register us with the system
    include Arachni::Report::Registrar

    # get the output interface
    include Arachni::UI::Output

    #
    # @param [Array]  audit  the result of the audit
    # @param [String]    outfile    where to save the report
    #
    def initialize( audit, outfile = nil )
        @audit   = audit
        @outfile = outfile + '.html'
        
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
            'Description'    => %q{Exports a report as an HTML document.},
            'Author'         => 'zapotek',
            'Version'        => '$Rev: 198 $',
        }
    end

    def __save( outfile, out )
        file = File.new( outfile, 'w' )
        file.write( out )
        file.close
    end

    def __prepare_data( )

        if( @audit['options']['exclude'] )
            @audit['options']['exclude'].each_with_index {
                |filter, i|
                @audit['options']['exclude'][i] = filter.to_s
            }
        end

        if( @audit['options']['include'] )
            @audit['options']['include'].each_with_index {
                |filter, i|
                @audit['options']['include'][i] = filter.to_s
            }
        end

        if( @audit['options']['redundant'] )
            @audit['options']['redundant'].each_with_index {
                |filter, i|
                @audit['options']['redundant'][i]['regexp'] = filter['regexp'].to_s
            }
        end

        if( @audit['options']['cookies'] )
            cookies = []
            @audit['options']['cookies'].each_pair {
                |name, value|
                cookies << { 'name'=> name, 'value' => value }
            }
            @audit['options']['cookies'] = cookies
        end

        @audit['vulns'].each_with_index {
            |vuln, i|

            refs = []
            res_headers = []
            req_headers = []
            vuln['references'].each_pair {
                |name, value|
                refs << { 'name'=> name, 'value' => value }
            }

            vuln['headers']['response'].each_pair {
                |name, value|
                res_headers << "#{name}: #{value}"
            }
            
            vuln['headers']['request'].each_pair {
                |name, value|
                req_headers << "#{name}: #{value}"
            }
            
            @audit['vulns'][i]['headers']['request']  = req_headers            
            @audit['vulns'][i]['headers']['response'] = res_headers
            @audit['vulns'][i]['references']         = refs
            @audit['vulns'][i]['escaped_response']   =
                Base64.encode64( vuln['response'] ).gsub( /\n/, '' )
        }

        tpl_data = {
            'arachni' => {
            'version'  => @audit['version'],
            'revision' => @audit['revision'],
            'options'  => @audit['options']
            },
            'audit' => {
            'vulns'    => @audit['vulns'],
            'date'     => @audit['date']
            }
        }
    end

end

end
end
