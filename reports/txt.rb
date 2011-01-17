=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end


module Arachni

require Options.instance.dir['reports'] + 'stdout'

module Reports

#
# Creates a plain text report of the audit.
#
# It redirects stdout to an outfile and runs the default (stdout.rb) report.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
class Text < Arachni::Report::Base

    #
    # @param [AuditStore]  audit_store
    # @param [Hash]        options    options passed to the report
    #
    def initialize( audit_store, options )
        @audit_store = audit_store
        @outfile     = options['outfile']

        # get an instance of the stdout report
        @__stdout_rep = Arachni::Reports::Stdout.new( audit_store, options )
    end

    def run( )

        print_line( )
        print_status( 'Creating text report...' )

        # redirect output streams to the outfile
        stdout = $stdout.dup
        stderr = $stderr.dup
        $stderr = $stdout = File.new( @outfile, 'w' )

        @__stdout_rep.run( )

        $stdout.close
        $stdout = stdout.dup
        $stderr = stderr.dup

        print_status( 'Saved in \'' + @outfile + '\'.' )
    end

    def self.info
        {
            :name           => 'Text report',
            :description    => %q{Exports a report as a plain text file.},
            :author         => 'zapotek',
            :version        => '0.2',
            :options        => [
                Arachni::OptString.new( 'outfile', [ false, 'Where to save the report.',
                    Time.now.to_s + '.txt' ] ),
            ]
        }
    end

end

end
end
