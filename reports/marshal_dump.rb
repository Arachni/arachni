=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

module Arachni
module Reports    
    
#
# MarshalDump report.
# Serializes and saves the audit results.
#
# Currently only for debugging.
#
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: $Rev$
#
class MarshalDump < Arachni::Report::Base
    
    # register us with the system
    include Arachni::Report::Registrar
    
    # get the output interface
    include Arachni::UI::Output

    #
    # @param [Array<Vulnerability>]  vulns  the array of detected vulnerabilities
    # @param [String]    outfile    where to save the report
    #
    def initialize( audit, outfile = 'marshal.dump' )
        @audit   = audit
        @outfile = outfile
    end
    
    #
    # REQUIRED
    #
    # Use it to run your report.
    #
    def run( )
        
        print_line( )
        print_status( 'Dumping audit results in \'' + @outfile + '\'.' )
        
        to_dump = Hash.new
        i = 0
        
        to_dump['version']  = @audit['version']
        to_dump['revision'] = @audit['revision']
        to_dump['options']  = @audit['options']
        to_dump['date']     = @audit['date'] 
        to_dump['vulns']    = []
            
        @audit['vulns'].each {
            |vulnerability|
            
            to_dump['vulns'][i] = Hash.new
            
            vulnerability.each { 
                |vuln|
                to_dump['vulns'][i] = to_dump['vulns'][i].merge( vuln )
            }
            i += 1
        }
        
        File.open( @outfile, 'w' ) {
            |f|
            Marshal.dump( to_dump, f )
        }
    
        print_status( 'Done!' )
    end
    
    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            'Name'           => 'MarshalDump',
            'Description'    => %q{Serializes and saves the audit results.},
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
        }
    end
    
end

end
end
