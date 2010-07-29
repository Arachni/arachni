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

    def __prepare_variations( vulns )
        
        variation_keys = [
            'injected',
            'id',
            'regexp',
            'regexp_match',
            'headers',
            'escaped_response'
        ]
        
        new_vulns = Hash.new
        vulns.each {
            |vuln|
            
            orig_url    = vuln['url']
            vuln['url'] = vuln['url'].split( /\?/ )[0]
            
            if( !new_vulns[vuln['__id']] )
                new_vulns[vuln['__id']]    = vuln
            end

            if( !new_vulns[vuln['__id']]['variations'] )
                new_vulns[vuln['__id']]['variations'] = []
            end
            
            new_vulns[vuln['__id']]['variations'] << {
                'url'           => orig_url,
                'injected'      => vuln['injected'],
                'id'            => vuln['id'],
                'regexp'        => vuln['regexp'],
                'regexp_match'  => vuln['regexp_match'],
                'headers'       => vuln['headers'],
                'escaped_response'    => vuln['escaped_response']
            }
            
            variation_keys.each {
                |key|
                new_vulns[vuln['__id']].delete( key )
            }
            
        }
        
        vuln_keys = new_vulns.keys
        new_vulns = new_vulns.to_a.flatten
        
        vuln_keys.each {
            |key|
            new_vulns.delete( key )
        }
        
        new_vulns
        
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
            
            @audit['vulns'][i]['__id']    =
                vuln['mod_name'] + '::' + vuln['elem'] + '::' +
                vuln['var'] + '::' + vuln['url'].split( /\?/ )[0]
                    
            @audit['vulns'][i]['headers']['request']  = req_headers            
            @audit['vulns'][i]['headers']['response'] = res_headers
            @audit['vulns'][i]['references']         = refs
            @audit['vulns'][i]['escaped_response']   =
                Base64.encode64( vuln['response'] ).gsub( /\n/, '' )
            
            @audit['vulns'][i].delete( 'response' )        
            
        }
        
        runtime = @audit['options']['runtime'].to_i
        f_runtime = [runtime/3600, runtime/60 % 60, runtime % 60].map {
            |t|
            t.to_s.rjust( 2, '0' )
        }.join(':')
     
        tpl_data = {
            'arachni' => {
                'version'  => @audit['version'],
                'revision' => @audit['revision'],
                'options'  => @audit['options'],
                'date'     => Time.now.to_s
            },
            'audit' => {
                'vulns'    => __prepare_variations( @audit['vulns'] ),
                'start_datetime'  => @audit['options']['start_datetime'].asctime,
                'finish_datetime' => @audit['options']['finish_datetime'].asctime,
                'runtime'         => f_runtime
            },
            'opts'     => @options
        }
    end

end

end
end
