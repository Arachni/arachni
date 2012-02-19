=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni

module Reports

#
# Creates a plain text report of the audit.
#
# It redirects stdout to an outfile and runs the default (stdout.rb) report.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version 0.2
#
class Text < Arachni::Report::Base

    #
    # @param [AuditStore]  audit_store
    # @param [Hash]        options    options passed to the report
    #
    def initialize( audit_store, options )
        @audit_store = audit_store
        @outfile     = options['outfile']

        require Options.instance.dir['reports'] + 'stdout'

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
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.2',
            :options        => [ Arachni::Report::Options.outfile( '.txt' ) ]
        }
    end

end

end
end
