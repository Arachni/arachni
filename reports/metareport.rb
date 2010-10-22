=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
    
require Options.instance.dir['reports'] + 'metareport/arachni_metareport.rb'
    
module Reports    
    
#
# Metareport
#
# Creates a file to be used with the Arachni MSF plug-in.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Metareport < Arachni::Report::Base
    
    # register us with the system
    include Arachni::Report::Registrar
    
    #
    # @param [AuditStore]  audit_store
    # @param [Hash]        options    options passed to the report
    # @param [String]      outfile    where to save the report
    #
    def initialize( audit_store, options = nil, outfile = nil )
        @audit_store = audit_store
        @outfile     = outfile + '.msf'
    end
    
    def run( )
        
        print_line( )
        print_status( 'Creating file for the Metasploit framework...' )

        msf = []

        @audit_store.vulns.each {
            |vuln|
            next if !vuln.metasploitable

            vuln.variations.each {
                |variation|

                if( ( method = vuln.method.dup ) != 'post' )
                    url = variation['url'].gsub( /\?.*/, '' )
                else
                    url = variation['url']
                end
                
                if( vuln.elem == 'cookie' || vuln.elem == 'header' )
                    method = vuln.elem
                end
                
                # pp vuln
                
                params = variation['opts'][:combo]['hash']
                params[vuln.var] = params[vuln.var].gsub( variation['opts'][:injected_orig], 'XXinjectionXX' )
                
                params[vuln.var] = URI.encode( params[vuln.var], ';' )
                
                cookies = sub_cookie( variation['headers']['request']['cookie'], params )
                variation['headers']['request']['cookie'] = cookies.dup
                
                # ap sub_cookie( variation['headers']['request']['cookie'], params )
                
                msf << ArachniMetareport.new( {
                    :host   => URI( url ).host,
                    :port   => URI( url ).port,
                    :vhost  => '',
                    :ssl    => URI( url ).scheme == 'https',
                    :path   => URI( url ).path,
                    :query  => URI( url ).query,
                    :method => method.upcase,
                    :params => params,
                    :headers=> variation['headers']['request'].dup,
                    :pname  => vuln.var,
                    :proof  => variation['regexp_match'],
                    :risk   => '',
                    :name   => vuln.name,
                    :description    =>  vuln.description,
                    :category   =>  'n/a',
                    :exploit    => vuln.metasploitable
                } )
            }
            
        }
        
        # pp msf

        outfile = File.new( @outfile, 'w')
        YAML.dump( msf, outfile )

        print_status( 'Saved in \'' + @outfile + '\'.' )
    end
    
    def sub_cookie( str, params )
        hash = {}
        str.split( ';' ).each {
            |cookie|
            k,v = cookie.split( '=', 2 )
            hash[k] = v
        }
        
        return hash.merge( params ).map{ |k,v| "#{k}=#{v}" }.join( ';' )
    end
    
    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            :name           => 'Metareport',
            :description    => %q{Creates a file to be used with the Arachni MSF plug-in.},
            :author         => 'zapotek',
            :version        => '0.1',
        }
    end
    
end

end
end
