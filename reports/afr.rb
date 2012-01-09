=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Reports

#
# Arachni Framework Report (.afr)
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class AFR < Arachni::Report::Base

    def run
        print_line
        print_status( 'Dumping audit results in \'' + @options['outfile']  + '\'.' )

        @audit_store.save( @options['outfile'] )

        print_status( 'Done!' )
    end

    def self.info
        {
            :name           => 'Arachni Framework Report',
            :description    => %q{Saves the file in the default Arachni Framework Report (.afr) format.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [ Arachni::Report::Options.outfile( '.afr' ) ]
        }
    end

end

end
end
