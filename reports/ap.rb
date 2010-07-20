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
# Awesome prints a marshal dump
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: $Rev$
#
class AP < Arachni::Report::Base
    
    # register us with the system
    include Arachni::Report::Registrar
    
    # get the output interface
    include Arachni::UI::Output

    #
    # @param [Array<Vulnerability>]  vulns  the array of detected vulnerabilities
    # @param [String]    outfile    where to save the report
    #
    def initialize( vulns, outfile = nil )
        @vulns   = vulns
    end
    
    #
    # REQUIRED
    #
    # Use it to run your report.
    #
    def run( )
        
        print_line( )
        print_status( 'Awesome printing marshal dump...' )
        
        ap @vulns
        
        print_status( 'Done!' )
    end
    
    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            'Name'           => 'AP',
            'Description'    => %q{Awesome prints a marshal dump.},
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
        }
    end
    
end

end
end
