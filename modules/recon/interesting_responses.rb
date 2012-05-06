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

require 'digest/md5'

module Arachni
module Modules

#
# Logs all non 200 (OK) and non 404 server responses.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class InterestingResponses < Arachni::Module::Base

    include Arachni::Module::Utilities

    IGNORE_CODES = [
        200,
        404
    ]

    MAX_ENTRIES = 100

    def prepare
        # we need to run only once
        @@__ran ||= false
    end

    def run
        return if @@__ran

        print_status( "Listening..." )

        # tell the HTTP interface to cal this block every-time a request completes
        @http.add_on_complete do |res|
            __log_results( res ) if !IGNORE_CODES.include?( res.code ) && !res.body.empty?
        end
    end

    def clean_up
        @@__ran = true
    end

    def self.info
        {
            :name           => 'Interesting responses',
            :description    => %q{Logs all non 200 (OK) server responses.},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.4',
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Interesting server response.},
                :description => %q{The server responded with a non 200 (OK) code. },
                :tags        => [ 'interesting', 'response', 'server' ],
                :cwe         => '',
                :severity    => Issue::Severity::INFORMATIONAL,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

    def __log_results( res )
        @@entries ||= 0
        return if @@entries > MAX_ENTRIES

        @@_loged ||= {
            :paths   => Set.new,
            :digests => Set.new
        }

        digest = Digest::MD5.hexdigest( res.body )
        path   = URI( res.effective_url ).path

        return if @@_loged[:paths].include?( path ) ||
            @@_loged[:digests].include?( digest )

        @@_loged[:paths]   << path
        @@_loged[:digests] << digest

        log_issue(
            :url          => res.effective_url,
            :method       => res.request.method.to_s.upcase,
            :id           => "Code: #{res.code.to_s}",
            :elem         => Issue::Element::SERVER,
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        )

        @@entries += 1
        # inform the user that we have a match
        print_ok( "Found an interesting response (Code: #{res.code.to_s})." )
    end

end
end
end
