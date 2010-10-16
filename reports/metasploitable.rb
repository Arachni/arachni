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
# Metasploitable
#
# Creates a file to be used with the Arachni MSF plug-in.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Metasploitable < Arachni::Report::Base
    
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

                datastore = {}
                                    
                injected_orig = URI.encode( URI.encode( vuln.opts[:injected_orig] ), ':/' )
                uri = variation['url'].gsub( injected_orig, 'XXinjectedXX' )
                    
                datastore['PHPURI']  = uri
                datastore['RHOST']   = URI( variation['url'] ).host
                datastore['RPORT']   = URI( variation['url'] ).port
                
                datastore['exploit'] = vuln.metasploitable
                    
                msf << datastore
            }
            
        }
        
        outfile = File.new( @outfile, 'w')
        YAML.dump( msf, outfile )

        print_status( 'Saved in \'' + @outfile + '\'.' )
    end
    
    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            :name           => 'Metasploitable report',
            :description    => %q{Creates a file to be used with the Arachni MSF plug-in.},
            :author         => 'zapotek',
            :version        => '0.1',
        }
    end
    
end

end
end
