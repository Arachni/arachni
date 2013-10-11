=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Provides a notice for issues uncovered by timing attacks when the affected audited
# pages returned unusually high response times to begin with.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.6
class Arachni::Plugins::TimingAttacks < Arachni::Plugin::Base

    is_distributable

    # look for issue by tag name
    TAG = 'timing'

    # response times of a page must be greater or equal to this
    # in order to be considered
    TIME_THRESHOLD = 0.6

    REMARK = 'This issue was discovered using a timing-attack but the audited ' +
        'page was exhibiting unusually high response times to begin with. ' +
        'This could be an indication that the logged issue is a false positive.'

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
            @times[url] += res.time

            # add up all requests for each path
            @counter[url] += 1
        end

        wait_while_framework_running
    end

    def run
        avg = {}

        # calculate average request time for each path
        @times.each_pair { |url, time| avg[url] = time / @counter[url] }

        inconclusive = framework.modules.issues.map.with_index do |issue, idx|
            response_time = avg[ uri_parse( issue.url ).up_to_path ]

            next if !issue.tags || !issue.tags.includes_tags?( TAG ) ||
                !response_time || response_time < TIME_THRESHOLD

            issue.add_remark :meta_analysis, REMARK

            # Requires manual verification.
            issue.verification = true

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
                while the affected web pages demonstrated an unusually high response time;
                a situation which renders the logged issues inconclusive or (possibly) false positives.

                Pages with high response times usually include heavy-duty processing
                which makes them prime targets for Denial-of-Service attacks.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.6',
            tags:        %w(anomaly timing attacks meta)
        }
    end

end
