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
# Awesome prints a marshal dump.
#
# Since Arachni report and profile files are marshalized objects this is<br/>
# a great way to see what's inside them.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: $Rev$
#
class AP < Arachni::Report::Base
    
    # register us with the system
    include Arachni::Report::Registrar
    
    # get the output interface
    include Arachni::UI::Output

    #
    # @param [Array]  audit  the result of the audit
    # @param [Hash]   options    options passed to the report
    # @param [String]    outfile    where to save the report
    #
    def initialize( audit, options = nil, outfile = nil )
        @audit   = audit
    end
    
    #
    # REQUIRED
    #
    # Use it to run your report.
    #
    def run( )
        
        print_line( )
        print_status( 'Awesome printing marshal dump...' )
        
        ap @audit
        
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
