=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

#
# Creates a plain text report of the audit.
#
# It redirects stdout to an outfile and runs the default (stdout.rb) report.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.1
#
class Arachni::Reports::Text < Arachni::Report::Base

    def run
        load Arachni::Options.dir['reports'] + 'stdout.rb'

        print_line
        print_status "Dumping audit results in #{outfile}."

        # redirect output streams to the outfile
        stdout  = $stdout.dup
        stderr  = $stderr.dup
        $stderr = $stdout = File.new( outfile, 'w' )

        Reports::Stdout.new( auditstore, options ).run

        $stdout.close
        $stdout = stdout.dup
        $stderr = stderr.dup

        print_status 'Done!'
    end

    def self.info
        {
            name:        'Text',
            description: %q{Exports the audit results as a text (.txt) file.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2.1',
            options:     [ Options.outfile( '.txt' ) ]
        }
    end

end
