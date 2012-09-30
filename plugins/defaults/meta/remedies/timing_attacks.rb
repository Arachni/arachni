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

#
# Provides a notice for issues uncovered by timing attacks when the affected audited
# pages returned unusually high response times to begin with.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.5
#
class Arachni::Plugins::TimingAttacks < Arachni::Plugin::Base

    is_distributable

    # look for issue by tag name
    TAG = 'timing'

    # response times of a page must be greater or equal to this
    # in order to be considered
    TIME_THRESHOLD = 0.6

    def prepare
        @times   = {}
        @counter = {}

        # run for each response as it arrives
        framework.http.add_on_complete do |res|
            # we don't care about non OK responses
            next if res.code != 200

            # let's hope for a proper and clean parse but be prepared for
            # all hell to break loose too...
            begin
                url = uri_parse( res.effective_url ).up_to_path
            rescue => e
                next
            end

            @counter[url] ||= @times[url] ||= 0

            # add up all request times for a specific path
            @times[url] += res.start_transfer_time

            # add up all requests for each path
            @counter[url] += 1
        end

        wait_while_framework_running
    end

    def run
        avg = {}

        # calculate average request time for each path
        @times.each_pair { |url, time| avg[url] = time / @counter[url] }

        inconclusive = framework.audit_store.issues.map.with_index do |issue, idx|
            next if !issue.tags || !issue.tags.includes_tags?( TAG ) ||
                avg[ uri_parse( issue.url ).up_to_path ] < TIME_THRESHOLD

            {
                'hash'   => issue.digest,
                'index'  => idx + 1,
                'url'    => issue.url,
                'name'   => issue.name,
                'var'    => issue.var,
                'elem'   => issue.elem,
                'method' => issue.method
            }
        end.compact

        register_results( inconclusive ) if !inconclusive.empty?
    end

    def self.merge( results )
        results.flatten
    end

    def self.info
        {
            name:        'Timing attack anomalies',
            description: %q{Analyzes the scan results and logs issues that used timing attacks
                while the affected web pages demonstrated an unusually high response time.
                A situation which renders the logged issues inconclusive or (possibly) false positives.

                Pages with high response times usually include heavy-duty processing
                which makes them prime targets for Denial-of-Service attacks.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.4',
            tags:        %w(anomaly timing attacks meta)
        }
    end

end
