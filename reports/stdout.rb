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
# Simple report tutorial.
# It outputs the vulnerabilities on stdout.
#
# Currently only for debugging.
#
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: $Rev$
#
class Stdout < Arachni::Report::Base
    
    # register us with the system
    include Arachni::Report::Registrar
    
    # get the output interface
    include Arachni::UI::Output

    #
    # @param [Array<Vulnerability>]  vulns  the array of detected vulnerabilities
    #
    def initialize( vulns )
        @vulns = vulns
    end
    
    #
    # REQUIRED
    #
    # Use it to run your report.
    #
    def run( )
        ap @vulns
    end
    
    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            'Name'           => 'Stdout',
            'Description'    => %q{Prints the results to standard output.},
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
        }
    end
    
end

end
end
