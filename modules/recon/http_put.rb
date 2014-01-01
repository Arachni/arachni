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
# HTTP PUT recon module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.5
#
class Arachni::Modules::HTTP_PUT < Arachni::Module::Base

    def self.substring
        @substring ||= 'PUT' + seed
    end

    def self.body
        @body ||= 'Created by Arachni. ' + substring
    end

    def run
        path = get_path( page.url ) + 'Arachni-' + seed.to_s[0..4].to_s
        return if audited?( path )
        audited( path )

        http.request( path, method: :put, body: self.class.body ) do |res|
            http.get( path ) { |c_res| check_and_log( c_res ) } if res.code == 201
        end
    end

    def check_and_log( res )
        return if !res.body.to_s.include?( self.class.substring )

        log( { element: Element::SERVER }, res )
        print_ok 'File has been created: ' + res.effective_url
    end

    def self.info
        {
            name:        'HTTP PUT',
            description: %q{Checks if uploading files is possible using the HTTP PUT method.},
            elements:    [ Element::SERVER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.4',
            targets:     %w(Generic),
            references: {
                'W3' => 'http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html'
            },
            issue:       {
                name:            %q{Publicly writable directory},
                description:     %q{3rd parties can upload files to the web-server.},
                tags:            %w(http methods put server),
                cwe:             '650',
                severity:        Severity::HIGH,
                remedy_guidance: %q{Disable the PUT method on the Web Server and/or disable write permissions to the web server directory.}
            }
        }
    end

end
