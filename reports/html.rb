=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

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
# Requires the Liquid (http://www.liquidmarkup.org/) gem:<br/>
#   sudo gem install liquid
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
    # @param [String]    outfile    where to save the report
    #
    def initialize( audit_store, options, outfile = 'report' )
        @audit_store   = audit_store
        @options       = options
        @outfile       = outfile + '.html'
    end

    #
    # Runs the HTML report.
    #
    def run( )

        print_line( )
        print_status( 'Creating HTML report...' )

        @template = Liquid::Template.parse( IO.read( @options['tpl'] ) )

        out = @template.render( __prepare_data( ) )

        __save( @outfile, out )

        print_status( 'Saved in \'' + @outfile + '\'.' )
    end

    def self.info
        {
            :name           => 'HTML Report',
            :description    => %q{Exports a report as an HTML document.},
            :author         => 'zapotek',
            :version        => '0.1',
            :options        => [
                Arachni::OptPath.new( 'tpl', [ false, 'Template to use.',
                    File.dirname( __FILE__ ) + '/html/default.tpl' ] ),
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

                if( variation['regexp'] )
                    variation['regexp'] = variation['regexp'].to_s
                end

                if( variation['response'] )
                    @audit_store.vulns[i].variations[j]['escaped_response'] =
                        Base64.encode64( variation['response'] ).gsub( /\n/, '' )

                    @audit_store.vulns[i].variations[j].delete( 'response' )
                end

                if( variation['headers']['request'].is_a?( Hash ) )
                    request = ''
                    variation['headers']['request'].each_pair {
                        |key,val|
                        request += "#{key}:\t#{val}\n"
                    }
                    @audit_store.vulns[i].variations[j]['headers']['request']=
                        request.clone
                end

                if( variation['headers']['response'].is_a?( Hash ) )
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

        hash['sitemap']   = @audit_store.sitemap
        hash['REPORT_FP'] = REPORT_FP

        return hash
    end

end

end
end
