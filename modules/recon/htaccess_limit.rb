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

#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.6
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
        print_ok 'Request was accepted: ' + res.effective_url
    end

    def self.info
        {
            name:        '.htaccess LIMIT misconfiguration',
            description: %q{Checks for misconfiguration in LIMIT directives that blocks
                GET requests but allows POST.},
            elements:    [ Element::SERVER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.6',
            targets:     %w(Generic),
            references: {
                'Apache.org' => 'http://httpd.apache.org/docs/2.2/mod/core.html#limit'
            },
            issue:       {
                name:        %q{Misconfiguration in LIMIT directive of .htaccess file},
                description: %q{There are a number of HTTP methods that can be 
                    used on a webserver, for example OPTIONS, HEAD, GET, POST, 
                    PUT, DELETE etc.  Each of these methods perform a different 
                    function, and each have an associate level of risk when 
                    their use is permitted on the webserver. The <Limit> 
                    directive within Apaches .htaccess file allows 
                    administrators to define which of the methods they would 
                    like to block. However as this is a blacklisting approach it 
                    is inevitable that a server administrator may accidently 
                    miss adding certain HTTP methods to be blocked, therefor 
                    increasing the level of risk to the application and/or 
                    server. For example the <Limit> directive may prevent PUT 
                    however will permit put (in lower case). Arachni discovered 
                    through method tampering that methods were able to be used 
                    in both upper and lower case. Therefor indicating the use of 
                    the less secure <Limit> directive.},
                tags:        %w(htaccess server limit),
                severity:    Severity::HIGH,
                remedy_guidance:  %q{The preferred configuration to prevent the 
                    use of unauthorised HTTP methods is to utilise the 
                    <LimitExcept> directive. This directive uses a whitelisting 
                    approach to permit HTTP methods while blocking all others 
                    not listed in the directive, and will therefor block any 
                    method tampering attempts. Most commonly, the only HTTP 
                    methods required for most scenarios are GET, and POST. An 
                    example of permitting these HTTP methods is: 
                    '<LimitExcept POST GET> require valid-user </LimitExcept>'}
            }
        }
    end

end
