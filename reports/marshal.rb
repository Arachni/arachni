=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Reports

#
# Converts the AuditStore to a Hash which it then dumps in Marshal format into a file.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Marshal < Arachni::Report::Base

    def run
        print_line( )
        print_status( 'Dumping audit results in \'' + @options['outfile']  + '\'.' )

        File.open( @options['outfile'], 'w' ) {
            |f|
            f.write( ::Marshal::dump( @audit_store.to_h ) )
        }

        print_status( 'Done!' )
    end

    def self.info
        {
            :name           => 'Marshal Report',
            :description    => %q{Exports the audit results as a Marshal file.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [ Arachni::Report::Options.outfile( '.marshal' ) ]
        }
    end

end

end
end
