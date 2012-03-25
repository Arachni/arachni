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
module Modules

#
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.1
#
class EMails < Arachni::Module::Base

    def run
        @@_logged ||= Set.new

        match_and_log( /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i ){
            |email|
            return false if @@_logged.include?( email )
            @@_logged << email
        }
    end

    def self.info
        {
            :name           => 'E-mail address',
            :description    => %q{Greps pages for disclosed e-mail addresses.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Disclosed e-mail address.},
                :description => %q{An e-mail address is being disclosed.},
                :cwe         => '200',
                :severity    => Issue::Severity::INFORMATIONAL,
                :cvssv2      => '0',
                :remedy_guidance    => %q{},
                :remedy_code => '',
            }
        }
    end

end
end
end
