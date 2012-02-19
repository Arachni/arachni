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
# WebDAV detection recon module.
#
# It doesn't check for a functional DAV implementation but uses the
# OPTIONS HTTP method to see if 'PROPFIND' is allowed.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.2
#
# @see http://en.wikipedia.org/wiki/WebDAV
# @see http://www.webdav.org/specs/rfc4918.html
#
class WebDav < Arachni::Module::Base

    include Arachni::Module::Utilities

    def prepare
        #
        # Because Dav may be enabled on a per directory basis we will check
        # all directories but only report the first one we find.
        #
        # If it is enabled for all dirs then we'll end up swimming in
        # noise.
        #
        # Result aggregation will be implemented at some point though...
        #
        @@__found ||= false

        @__check = 'PROPFIND'

        @@__auditted ||= Set.new
    end

    def run
        path = get_path( @page.url )
        return if @@__found || @@__auditted.include?( path )

        print_status( "Checking: #{path}" )

        @http.request( path, :method => :options ).on_complete {
            |res|
            begin
                allowed = res.headers_hash['Allow'].split( ',' ).map{ |method| method.strip }
                __log_results( res ) if allowed.include?( @__check )
            rescue
            end
        }

        @@__auditted << path
    end

    def self.info
        {
            :name           => 'WebDav',
            :description    => %q{Checks for WebDAV enabled directories.},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.2',
            :references     => {
                'WebDAV.org'    => 'http://www.webdav.org/specs/rfc4918.html',
                'Wikipedia'    => 'http://en.wikipedia.org/wiki/WebDAV',
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{WebDAV},
                :description => %q{WebDAV is enabled on the server.
                    Consider auditing further using a specialised tool.},
                :tags        => [ 'webdav', 'options', 'methods', 'server' ],
                :cwe         => '',
                :severity    => Issue::Severity::INFORMATIONAL,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

    def __log_results( res )
        return if @@__found

        @@__found = true

        log_issue(
            :url          => res.effective_url,
            :method       => res.request.method.to_s.upcase,
            :elem         => Issue::Element::SERVER,
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        )

        # inform the user that we have a match
        print_ok( "Enabled for: #{res.effective_url}" )
    end

end
end
end
