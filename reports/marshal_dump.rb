=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Reports    
    
#
# MarshalDump report.
#    
# Serializes and saves the audit results.<br/>
# This report is only used by Arachni internally to create a marshal<br/>
# dump of audit results.
#
# Then the dump-file can be loaded by Arachni to create new types of reports.             
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: $Rev$
#
class MarshalDump < Arachni::Report::Base
    
    # register us with the system
    include Arachni::Report::Registrar
    
    # get the output interface
    include Arachni::UI::Output

    #
    # @param [Array]  audit  the result of the audit
    # @param [Hash]   options    options passed to the report
    # @param [String]    outfile    where to save the report
    #
    def initialize( audit, options = nil, outfile = 'marshal.dump' )
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
        
        to_dump          = @audit.dup
        to_dump['vulns'] = []
        
        to_dump['options'] = Hash.new
        @audit['options'].each_pair {
            |key, value|
            to_dump['options'][__normalize( key )] = value
        }
    
        to_dump['options']['url'] = @audit['options'][:url].to_s
            
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
    
    private
    
    def __normalize( key )
        return key.to_s
    end
    
end

end
end
