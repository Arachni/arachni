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
# @version 0.1.1
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
            version:     '0.1.1',
            targets:     %w(Generic),
            issue:       {
                name:            %q{Exposed localstart.asp page},
                description:     %q{The default management ISS page localstart.asp
                    is still on the server.},
                tags:            %w(asp iis server),
                severity:        Severity::LOW
            }
        }
    end

end
