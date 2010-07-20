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

class Stdout < Arachni::Report::Base
    
    include Arachni::Report::Registrar
    include Arachni::UI::Output

    def initialize( vulns )
        @vulns = vulns
    end
    
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
            'Description'    => %q{Prints the results on standard output.},
            'Author'         => 'zapotek',
            'Version'        => '$Rev: 155 $',
        }
    end
    
end

end
end
