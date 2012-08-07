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

#
# Looks for and logs e-mail addresses.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Arachni::Modules::EMails < Arachni::Module::Base

    def run
        match_and_log( /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i ) do |email|
            return false if audited?( email )
            audited( email )
        end
    end

    def self.info
        {
            name:        'E-mail address',
            description: %q{Greps pages for disclosed e-mail addresses.},
            elements:    [ Element::BODY ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            references: {
                  'Wikipedia' => 'http://en.wikipedia.org/wiki/Address_munging'
            },
            version:     '0.1.1',
            targets:     %w(Generic),
            issue:       {
                name:            %q{Disclosed e-mail address.},
                description:     %q{An e-mail address is being disclosed.},
                cwe:             '200',
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{E-mail addresses should be presented in such a way that it is hard to process them automatically.} 
            }
        }
    end

end
