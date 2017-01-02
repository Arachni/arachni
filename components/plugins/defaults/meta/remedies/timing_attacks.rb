=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Provides a notice for issues uncovered by timing attacks when the affected audited
# pages returned unusually high response times to begin with.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Plugins::TimingAttacks < Arachni::Plugin::Base

    is_distributable

    # Look for issue by tag name.
    TAG = 'timing'

    # Response times of a page must be greater or equal to this
    # in order to be considered.
    TIME_THRESHOLD = 0.6

    REMARK = 'This issue was discovered using a timing-attack but the audited ' +
        'page was exhibiting unusually high response times to begin with. ' +
        'This could be an indication that the logged issue is a false positive.'

    def prepare
        @times   = {}
        @counter = {}
    end

    def restore( data )
        @times, @counter = *data
    end

    def run
        # Run for each response as it arrives.
        http.on_complete do |response|
            # We don't care about non OK responses.
            next if response.code != 200

            url = response.parsed_url.up_to_path.persistent_hash

            @counter[url] ||= @times[url] ||= 0

            # Add up all request times for a specific path.
            @times[url] += response.time

            # Add up all requests for each path.
            @counter[url] += 1
        end

        wait_while_framework_running

        avg = {}

        # Calculate average request time for each path.
        @times.each_pair { |url, time| avg[url] = time / @counter[url] }

        Data.issues.each do |issue|
            response_time = avg[uri_parse( issue.vector.action ).up_to_path.persistent_hash]
            next if !issue.tags.includes_tags?( TAG ) || !response_time ||
                response_time < TIME_THRESHOLD

            issue.add_remark :meta_analysis, REMARK

            # Requires manual verification.
            issue.trusted = false
        end
    end

    def suspend
        [@times, @counter]
    end

    def self.info
        {
            name:        'Timing attack anomalies',
            description: %q{
Analyzes the scan results and logs issues that used timing attacks while the
affected web pages demonstrated an unusually high response time; a situation
which renders the logged issues inconclusive or (possibly) false positives.

Pages with high response times usually include heavy-duty processing which makes
them prime targets for Denial-of-Service attacks.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.3.1',
            tags:        %w(anomaly timing attacks meta)
        }
    end

end
