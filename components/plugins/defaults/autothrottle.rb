=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Auto adjusts HTTP throughput for maximum network utilization.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.4
#
class Arachni::Plugins::AutoThrottle < Arachni::Plugin::Base

    is_distributable

    # Will decrease concurrency if avg response times are bellow this threshold -- in ms.
    THRESHOLD = 0.9

    # Easy on the throttle.
    STEP_UP   = 1

    # Hard on the breaks.
    STEP_DOWN = -3

    # Don't drop bellow this.
    MIN_CONCURRENCY = 2

    def prepare
        http = framework.http

        # run for each response as it arrives
        http.add_on_complete do
            # adjust on a per-burst basis
            next if http.burst_response_count == 0 ||
                http.burst_response_count % http.max_concurrency != 0

            print_debug "Max concurrency: #{http.max_concurrency}"

            if( http.max_concurrency > MIN_CONCURRENCY &&
                http.burst_average_response_time > THRESHOLD ) ||
                http.max_concurrency > framework.opts.http.request_concurrency

                step = http.max_concurrency + STEP_DOWN < MIN_CONCURRENCY ?
                    MIN_CONCURRENCY - http.max_concurrency : STEP_DOWN

                print_debug "Stepping down!: #{step}"
                http.max_concurrency = http.max_concurrency + step

            elsif http.burst_average_response_time < THRESHOLD &&
                http.max_concurrency < framework.opts.http.request_concurrency

                print_debug "Stepping up!: +#{STEP_UP}"
                http.max_concurrency = http.max_concurrency + STEP_UP
            end
        end
    end

    def self.info
        {
            name:        'AutoThrottle',
            description: %q{Monitors HTTP response times and automatically
                throttles the request concurrency in order to maintain stability
                and avoid from killing the server.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            tags:        %w(meta http throttle),
            version:     '0.1.4'
        }
    end

end
