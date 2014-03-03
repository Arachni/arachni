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

# HTTP PUT recon module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.6
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
            version:     '0.1.6',
            targets:     %w(Generic),
            references: {
                'W3' => 'http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html'
            },
            issue:       {
                name:            %q{Publicly writable directory},
                description:     %q{There are various methods in which a file (or
                    files) may be uploaded to a webserver. One method that can be
                    used is the HTTP PUT method. The PUT method is mainly used 
                    during development of applications and allows developers to
                    upload (or put) files on the server within the web root. By 
                    nature of the design, the PUT method typically does not 
                    provide any filtering and therefore allows sever side
                    executable code (PHP, ASP, etc) to be uploaded to the 
                    server. Cyber-criminals will search for servers supporting 
                    the PUT method with the intention of modifying existing 
                    pages, or uploading web shells to take control of the 
                    server. Arachni has discovered that the affected path allows 
                    clients to use the PUT method. During this test, Arachni has 
                    PUT a file on the server within the web root and
                    successfully performed a GET request to its location and 
                    matched the contents.},
                tags:            %w(http methods put server),
                cwe:             '650',
                severity:        Severity::HIGH,
                remedy_guidance: %q{Where possible the HTTP PUT method should be 
                    globally disabled. This can typically be done with a simple 
                    configuration change on the server. The steps to disable the 
                    PUT method will differ depending on the type of server being 
                    used (IIS, Apache, etc.). For cases where the PUT method is 
                    required to meet application functionality, such as REST 
                    style web services, strict limitations should be
                    implemented to ensure that only secure (SSL/TLS enabled), 
                    and authorised clients are permitted to use the PUT method. 
                    Additionally, the server's file system permissions should
                    also enforce strict limitations.}
            }
        }
    end

end
