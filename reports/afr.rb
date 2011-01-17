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
# Arachni Framework Report (.afr)
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class AFR < Arachni::Report::Base

    #
    # @param [AuditStore]  audit_store
    # @param [Hash]   options    options passed to the report
    #
    def initialize( audit_store, options )
        @audit_store   = audit_store
        @options       = options
    end

    def run( )

        print_line( )
        print_status( 'Dumping audit results in \'' + @options['outfile']  + '\'.' )

        @audit_store.save( @options['outfile'] )

        print_status( 'Done!' )
    end

    def self.info
        {
            :name           => 'Arachni Framework Report',
            :description    => %q{Saves the file in the default Arachni Framework Report (.afr) format.},
            :author         => 'zapotek',
            :version        => '0.1',
            :options        => [
                Arachni::OptString.new( 'outfile', [ false, 'Where to save the report.',
                    Time.now.to_s + '.afr' ] ),
            ]
        }
    end

end

end
end
