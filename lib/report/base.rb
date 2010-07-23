=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Report

#
# Arachni::Report::Base class
#    
# An abstract class for the reports.<br/>
# All reports must extend this.
#
# @author: Anastasios "Zapotek" Laskos 
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1-pre
# @abstract
#
class Base
    
    #
    # REQUIRED
    #
    def run( )
        
    end
    
    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            'Name'           => '',
            'Description'    => %q{},
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
        }
    end
    
end

end
end
