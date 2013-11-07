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
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Arachni::Plugins::UncommonHeaders < Arachni::Plugin::Base

    is_distributable

    COMMON = Set.new([
         'content-type',
         'content-length',
         'server',
         'connection',
         'accept-ranges',
         'age',
         'allow',
         'cache-control',
         'content-encoding',
         'content-language',
         'content-range',
         'date',
         'etag',
         'expires',
         'last-modified',
         'location',
         'pragma',
         'proxy-authenticate',
         'set-cookie',
         'trailer',
         'transfer-encoding'
    ])

    def prepare
        @headers_per_url = Hash.new do |h, url|
            h[url] = {}
        end
    end

    def run
        http.add_on_complete do |response|
            headers = response.headers_hash.
                select { |name, _| !COMMON.include?( name.to_s.downcase ) }
            next if headers.empty?

            @headers_per_url[response.effective_url].merge! headers
        end
    end

    def clean_up
        wait_while_framework_running
        register_results @headers_per_url
    end

    def self.merge( results )
        merged = Hash.new do |h, url|
            h[url] = {}
        end

        results.each do |headers_per_url|
            headers_per_url.each do |url, headers|
                merged[url].merge! headers
            end
        end

        merged
    end

    def self.info
        {
            name:        'Uncommon headers',
            description: %q{Intercepts HTTP responses and logs uncommon headers.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1'
        }
    end

end
