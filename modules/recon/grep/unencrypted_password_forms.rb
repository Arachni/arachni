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
# Unencrypted password form
#
# Looks for password inputs that don't submit data over an encrypted channel (HTTPS).
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version 0.1.4
#
# @see http://www.owasp.org/index.php/Top_10_2010-A9-Insufficient_Transport_Layer_Protection
#
class UnencryptedPasswordForms < Arachni::Module::Base

    def prepare
        @@__audited ||= Set.new
    end

    def run
        @page.forms.each {
            |form|
            __check( form )
        }
    end

    def __check( form )

        scheme = URI( form.action ).scheme
        return if( scheme.downcase == 'https' )

        return if !form.raw['auditable']
        form.raw['auditable'].each {
            |input|

            next if !input['type']

            if( input['type'].downcase == 'password' )
                __log( form.url, input )
            end
        }
    end

    def __log( url, input )

        if @@__audited.include?( input['name'] )
            print_info( 'Skipping already checked form \'' +
                input['name'] + '\' of url: ' + url )
            return
        end

        name = input['name'] || input['id'] || 'n/a'
        @@__audited << name

        log_issue(
            :var          => name,
            :url          => url,
            :elem         => Issue::Element::FORM,
            :response     => @page.html,
        )

        print_ok( "Found unprotected password field '#{input['name']}' at #{url}" )

    end

    def self.info
        {
            :name           => 'UnencryptedPasswordForms',
            :description    => %q{Looks for password inputs that don't submit data
                over an encrypted channel (HTTPS).},
            :elements       => [
                Issue::Element::FORM
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1.4',
            :references     => {
                'OWASP Top 10 2010' => 'http://www.owasp.org/index.php/Top_10_2010-A9-Insufficient_Transport_Layer_Protection'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Unencrypted password form.},
                :description => %q{Transmission of password does not use an encrypted channel.},
                :tags        => [ 'unencrypted', 'password', 'form' ],
                :cwe         => '319',
                :severity    => Issue::Severity::MEDIUM,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

end
end
end
