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
module Plugins

#
# Provides a notice for issues uncovered by timing attacks when the affected audited
# pages returned unusually high response times to begin with.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version 0.1.4
#
class TimingAttacks < Arachni::Plugin::Base

    include Arachni::Module::Utilities

    # look for issue by tag name
    TAG            = 'timing'

    # response times of a page must be greater or equal to this
    # in order to be considered
    TIME_THRESHOLD = 0.6

    def prepare
        @times = {}
        @counter = {}

        # run for each response as it arrives
        @framework.http.add_on_complete {
            |res|

            # we don't care about non OK responses
            next if res.code != 200

            begin
                path = nil
                # let's hope for a proper and clean parse but be prepared for
                # all hell to break loose too...
                begin
                    path = URI( normalize_url( res.effective_url ) ).path
                rescue
                    url = res.effective_url.split( '?' ).first
                    path = URI( normalize_url( res.effective_url ) ).path
                end

                path = '/' if path.empty?
                @counter[path] ||= @times[path] ||= 0

                # add up all request times for a specific path
                @times[path] += res.start_transfer_time

                # add up all requests for each path
                @counter[path] += 1
            rescue
            end
        }

        wait_while_framework_running
    end

    def run
        avg = get_avg

        # will hold the hash IDs of inconclusive issues
        inconclusive = []
        @framework.audit_store.issues.each_with_index {
            |issue, idx|
            if issue.tags && issue.tags.include?( TAG ) &&
                avg[ URI( normalize_url( issue.url ) ).path ] >= TIME_THRESHOLD

                inconclusive << {
                    'hash'   => issue._hash,
                    'index'  => idx + 1,
                    'url'    => issue.url,
                    'name'   => issue.name,
                    'var'    => issue.var,
                    'elem'   => issue.elem,
                    'method' => issue.method
                }
            end
        }

        register_results( inconclusive ) if !inconclusive.empty?
    end

    def get_avg
        avg ={}

        # calculate average request time for each path
        @times.each_pair {
            |path, time|
            avg[path] = time / @counter[path]
        }

        return avg
    end

    def self.distributable?
        true
    end

    def self.merge( results )
        results.flatten
    end

    def self.info
        {
            :name           => 'Timing attack anomalies',
            :description    => %q{Analyzes the scan results and logs issues that used timing attacks
                while the affected web pages demonstrated an unusually high response time.
                A situation which renders the logged issues inconclusive or (possibly) false positives.

                Pages with high response times usually include heavy-duty processing
                which makes them prime targets for Denial-of-Service attacks.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.4',
            :tags           => [ 'anomaly' , 'timing', 'attacks', 'meta' ]
        }
    end

end

end
end
