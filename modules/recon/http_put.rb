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
# HTTP PUT recon module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.4
#
class HTTP_PUT < Arachni::Module::Base

    include Arachni::Module::Utilities

    def prepare
        @@__checked ||= Set.new
    end

    def run
        path = get_path( @page.url ) + 'Arachni-' + seed.to_s[0..4].to_s
        return if @@__checked.include?( path )
        @@__checked << path

        body = 'Created by Arachni. PUT' + seed

        http.request( path, :method => :put, :body => body ) do |res|
            next if res.code != 201
            http.get( path ) do |res|
                __log_results( res ) if res.body && res.body.substring?( 'PUT' + seed )
            end
        end
    end

    def self.info
        {
            :name           => 'HTTP PUT',
            :description    => %q{Checks if uploading files is possible using the HTTP PUT method.},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.4',
            :references     => {},
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{HTTP PUT is enabled.},
                :description => %q{3rd parties can upload files to the web-server.},
                :tags        => [ 'http', 'methods', 'put', 'server' ],
                :cwe         => '650',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }
        }
    end

    def __log_results( res )
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

        print_ok( 'File has been created: ' + res.effective_url )
    end

end
end
end
