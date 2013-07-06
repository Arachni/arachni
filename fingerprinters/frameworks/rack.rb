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

module Arachni
module Platform::Fingerprinters

#
# Identifies Rack applications.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
#
class Rack < Platform::Fingerprinter

    SESSIONID = 'rack.session'
    ID        = 'mod_rack'

    def run
        return if !cookies.include?( SESSIONID ) &&
            !server_or_powered_by_include?( ID )
        platforms << :ruby << :rack
    end

end

end
end
