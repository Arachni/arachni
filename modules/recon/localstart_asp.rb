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

# localstart.asp recon module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
class Arachni::Modules::LocalstartASP < Arachni::Module::Base

    def run
        return if page.platforms.languages.any? && !page.platforms.languages.include?( :asp )

        path = get_path( page.url )
        return if audited?( path )
        audited path

        http.get( "#{path}/#{seed}" ) do |response|
            # If it needs auth by default then don't bother checking because
            # we'll get an FP.
            next if response.code == 401

            url = "#{path}/localstart.asp"

            print_status "Checking: #{url}"
            http.get( url, &method( :check_and_log ) )
        end
    end

    def check_and_log( response )
        return if response.code != 401

        log( { element: Element::SERVER }, response )
    end

    def self.info
        {
            name:        'localstart.asp',
            description: %q{Checks for localstart.asp.},
            elements:    [ Element::SERVER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.2',
            targets:     %w(Generic),
            issue:       {
                name:            %q{Exposed localstart.asp page},
                description:     %q{To restrict access to specific pages on a 
                    webserver, developers can implement various methods of 
                    authentication, therefore only allowing access to clients
                    with valid credentials. There are several forms of
                    authentication that can be used. The simplest forms of 
                    authentication are known as 'Basic' and 'Basic Realm'. 
                    These methods of authentication have several known 
                    weaknesses such as being susceptible to brute force attacks. 
                    Additionally, when utilising the NTLM mechanism in a windows
                    environment, several disclosures of information exist, and 
                    any brute force attack occurs against the server's local 
                    users, or domain users if the web server is a domain
                    member. Cyber-criminals will attempt to locate protected 
                    pages to gain access to them and also perform brute force
                    attacks to discover valid credentials. Arachni discovered
                    the following page requires NTLM based basic authentication
                    in order to be accessed.},
                tags:            %w(asp iis server),
                severity:        Severity::LOW,
                remedy_guidance: %q{If the pages being protected are not 
                    required for the functionality of the web application they 
                    should be removed, otherwise, it is recommended that basic
                    and basic realm authentication are not used to protect 
                    against pages requiring authentication. If NTLM based basic 
                    authentication must be used, then default server and domain 
                    accounts such as 'administrator' and 'root' should be disabled,
                    as these will undoubtedly be the first accounts to be 
                    targeted in any such attack. Additionally, the webserver
                    should not be joined to any corporate domain where usernames 
                    are readily available (such as from email addresses). If the 
                    pages are required, and it is possible to remove the basic 
                    authentication, then a stronger and more resilient form-based
                    authentication mechanism should be implemented to protect the
                    affected pages.}
            }
        }
    end

end
