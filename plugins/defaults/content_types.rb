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
# Logs content-types of all server responses.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.5
#
class Arachni::Plugins::ContentTypes < Arachni::Plugin::Base

    is_distributable

    def prepare
        @results = {}
        @exclude = Regexp.new( options['exclude'] )

        @logged = Arachni::Support::LookUp::HashSet.new
    end

    def run
        framework.http.add_on_complete do |res|
            next if skip?( res )

            type = res.content_type
            type = type.join( ' - ' ) if type.is_a?( Array )

            @results[type] ||= []
            @results[type] << {
                url:    res.effective_url,
                method: res.request.method.to_s.upcase,
                params: res.request.params
            }

            log( res )
        end
    end

    def skip?( res )
        logged?( res ) || res.content_type.to_s.empty? || !log?( res )
    end

    def log?( res )
        options['exclude'].empty? || !res.content_type.to_s.match( @exclude )
    end

    def logged?( res )
        @logged.include?( log_id( res ) )
    end

    def log( res )
        @logged << log_id( res )
    end

    def log_id( res )
        res.request.method.to_s.upcase + res.effective_url
    end

    def clean_up
        wait_while_framework_running
        register_results( @results )
    end

    def self.merge( results )
        merged = {}

        results.each do |result|
            result.each do |type, val|
                merged[type] ||= []
                merged[type] |= val
            end
        end

        merged
    end

    def self.info
        {
            name:        'Content-types',
            description: %q{Logs content-types of server responses.
                It can help you categorize and identify publicly available file-types
                which in turn can help you identify accidentally leaked files.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.5',
            options:     [
                Options::String.new( 'exclude',
                    [false, 'Exclude content-types that match this regular expression.', 'text']
                )
            ]
        }
    end

end
