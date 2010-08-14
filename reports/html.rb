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
    # @param [AuditStore]  audit_store
    # @param [Hash]   options    options passed to the report
    # @param [String]    outfile    where to save the report
    #
    def initialize( audit_store, options, outfile = html )
        @audit_store   = audit_store
        @options       = options
        @outfile       = outfile + '.html'
        
        @tpl = File.dirname( __FILE__ ) + '/html/templates/index.tpl'
    end

    #
    # Runs the HTML report.
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

    private
    
    def __save( outfile, out )
        file = File.new( outfile, 'w' )
        file.write( out )
        file.close
    end

    def __prepare_data( )

        @audit_store.vulns.each_with_index {
            |vuln, i|

            if( vuln.references )
                refs = []
                vuln.references.each_pair {
                    |name, value|
                    refs << { 'name' => name, 'value' => value }
                }
                                
                @audit_store.vulns[i].references = refs
            end
        
            vuln.variations.each_with_index {
                |variation, j|
                
                if( variation['response'] )
                    @audit_store.vulns[i].variations[j]['escaped_response'] =
                        Base64.encode64( variation['response'] ).gsub( /\n/, '' )
                    
                    @audit_store.vulns[i].variations[j].delete( 'response' )
                end
                
                if( variation['headers']['request'] )
                    request = ''
                    variation['headers']['request'].each_pair {
                        |key,val|
                        request += "#{key}:\t#{val}\n"
                    }
                    @audit_store.vulns[i].variations[j]['headers']['request']=
                        request.clone
                end
                
                if( variation['headers']['response'] )
                    response = ''
                    variation['headers']['response'].each_pair {
                        |key,val|
                        response += "#{key}:\t#{val}\n"
                    }
                    @audit_store.vulns[i].variations[j]['headers']['response']=
                        response.clone
                end
                    
            }
            
        }
     
        hash = @audit_store.to_h
        
        hash['date'] = Time.now.to_s
        hash['opts'] = @options

        if( hash['options']['cookies'] )
            cookies = []
            hash['options']['cookies'].each_pair {
                |name, value|
                cookies << { 'name' => name, 'value' => value }
            }
            
            hash['options']['cookies'] = cookies
        end
        
        hash['sitemap']  = @audit_store.sitemap
        return hash
    end

end

end
end
