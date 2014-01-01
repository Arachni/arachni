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

# Converts the AuditStore to a Hash which it then dumps in YAML format into a file.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
class Arachni::Reports::YAML < Arachni::Report::Base

    def run
        print_line
        print_status "Dumping audit results in #{outfile}."

        File.open( options['outfile'], 'w' ) do |f|
            f.write( auditstore.to_hash.to_yaml )
        end

        print_status 'Done!'
    end

    def self.info
        {
            name:         'YAML',
            description:  %q{Exports the audit results as a YAML (.yaml) file.},
            content_type: 'application/x-yaml',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:      '0.1.1',
            options:      [ Options.outfile( '.yaml' ) ]
        }
    end

end
