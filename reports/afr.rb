=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

# Arachni Framework Report (.afr)
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.3
class Arachni::Reports::AFR < Arachni::Report::Base

    def run
        print_line
        print_status "Dumping audit results in '#{outfile}'."

        auditstore.save( outfile )

        print_status 'Done!'
    end

    def self.info
        {
            name:         'Arachni',
            description:  %q{Exports the audit results as an Arachni Framework Report (.afr) file.},
            content_type: 'application/x-afr',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:      '0.1.1',
            options:      [ Arachni::Report::Options.outfile( '.afr' ) ]
        }
    end

end
