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

# Converts the AuditStore to a Hash which it then dumps in Marshal format into a file.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
class Arachni::Reports::Marshal < Arachni::Report::Base

    def run
        print_line
        print_status "Dumping audit results in #{outfile}."

        File.open( outfile, 'w' ) do |f|
            f.write ::Marshal::dump( auditstore.to_hash )
        end

        print_status 'Done!'
    end

    def self.info
        {
            name:         'Marshal',
            description:  %q{Exports the audit results as a Marshal (.marshal) file.},
            content_type: 'application/x-marshal',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:      '0.1.1',
            options:      [Options.outfile('.marshal')]
        }
    end

end
