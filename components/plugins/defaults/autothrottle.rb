=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Auto adjusts HTTP throughput for maximum network utilization.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Plugins::AutoThrottle < Arachni::Plugin::Base

    is_distributable

    # Will decrease concurrency if the average response time for each burst is
    # above this threshold.
    #
    # One second per response does not exactly say healthy server.
    THRESHOLD = 1

    # Easy on the throttle.
    STEP_UP   = 1

    # Hard on the breaks.
    STEP_DOWN = -2

    # Don't drop bellow this.
    MIN_CONCURRENCY = 2

    def prepare
        http = framework.http

        # Run for each response as it arrives
        http.on_complete do
            # Adjust on a per-burst basis.
            next if http.burst_response_count == 0 ||
                http.burst_response_count % http.max_concurrency != 0

            response_time = http.burst_average_response_time

            if http.max_concurrency > MIN_CONCURRENCY &&
                response_time >= THRESHOLD

                # No-matter what, don't fall bellow the minimum concurrency.
                http.max_concurrency = [
                    http.max_concurrency + STEP_DOWN,
                    MIN_CONCURRENCY
                ].max

                print_info "Decreasing HTTP request concurrency to #{http.max_concurrency}."
                print_info "Average response time for this burst: #{response_time}"

            elsif http.max_concurrency < http.original_max_concurrency &&
                response_time < THRESHOLD

                # No-matter what, don't exceed the original maximum concurrency.
                http.max_concurrency = [
                    http.max_concurrency + STEP_UP,
                    http.original_max_concurrency
                ].min

                print_info "Increasing HTTP request concurrency to #{http.max_concurrency} (+#{STEP_UP})."
                print_info "Average response time for this burst: #{response_time}"
            end
        end
    end

    def self.info
        {
            name:        'AutoThrottle',
            description: %q{
Monitors HTTP response times and automatically throttles the request concurrency
in order to maintain stability and avoid from killing the server.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            tags:        %w(meta http throttle),
            version:     '0.1.6'
        }
    end

end
