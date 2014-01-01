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

require 'ap'

#
# Awesome prints an {AuditStore#to_hash} hash.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Arachni::Reports::AP < Arachni::Report::Base

    def run
        print_line
        print_status 'Awesome printing AuditStore as a Hash...'

        ap auditstore.to_hash

        print_status 'Done!'
    end

    def self.info
        {
            name:        'AP',
            description: %q{Awesome prints an AuditStore hash.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1'
        }
    end

end
