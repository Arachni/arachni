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

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Arachni::Modules::XForwardedAccessRestrictionBypass < Arachni::Module::Base

    def run
        return if ![401, 403].include?( page.code )
        http.get( page.url, headers: { 'X-Forwarded-For' => '127.0.0.1' } ) do |res|
            check_and_log( res )
        end
    end

    def check_and_log( res )
        return if res.code != 200
        log( { element: Element::SERVER }, res )
        print_ok "Request was accepted: #{res.effective_url}"
    end

    def self.info
        {
            name:        'X-Forwarded-For Access Restriction Bypass',
            description: %q{Retries denied requests with a X-Forwarded-For header
                to trick the web application into thinking that the request originates
                from localhost and checks whether the restrictions was bypassed.},
            elements:    [ Element::SERVER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            targets:     %w(Generic),
            issue:       {
                name:        %q{Access restriction bypass via X-Forwarded-For},
                description: %q{Access restrictions can be bypassed by tricking
                    the web application into thinking that the request originated
                    from localhost.},
                tags:        %w(access restriction server bypass),
                severity:    Severity::HIGH
            }
        }
    end

end
