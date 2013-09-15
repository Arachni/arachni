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

#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.5
#
class Arachni::Modules::Htaccess < Arachni::Module::Base

    def run
        return if page.code != 401

        [:post, :head, :blah]. each do |m|
            http.request( page.url, method: m ) { |res| check_and_log( res ) }
        end
    end

    def check_and_log( res )
        return if res.code != 200
        log( { element: Element::SERVER }, res )
        print_ok 'Request was accepted: ' + res.url
    end

    def self.info
        {
            name:        '.htaccess LIMIT misconfiguration',
            description: %q{Checks for misconfiguration in LIMIT directives that blocks
                GET requests but allows POST.},
            elements:    [ Element::SERVER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.5',
            targets:     %w(Generic),
            references: {
                'Apache.org' => 'http://httpd.apache.org/docs/2.2/mod/core.html#limit'
            },
            issue:       {
                name:        %q{Misconfiguration in LIMIT directive of .htaccess file},
                description: %q{The .htaccess file blocks GET requests but allows POST.},
                tags:        %w(htaccess server limit),
                severity:    Severity::HIGH,
                remedy_guidance:  %q{Do not use the LIMIT tag.
                    If you are in a situation where you want to allow specific request methods, you should use LimitExcept instead.}
            }
        }
    end

end
