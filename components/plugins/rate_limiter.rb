=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Rate limiter for HTTP requests
#
# @author Bert Hekman <bert@pbwebmedia.com>
class Arachni::Plugins::RateLimiter < Arachni::Plugin::Base

    @@times_slept      = 0
    @@total_time_slept = 0.0

    is_distributable

    def prepare
        http = framework.http

        last_count             = 0
        last_response_time_sum = 0.0

        http.on_queue do
            last_count             = 0
            last_response_time_sum = 0.0
        end

        http.on_complete do
            # Sleep once per burst.
            next if http.burst_response_count == 0 ||
                http.burst_response_count % http.max_concurrency != 0

            burst_response_count = http.burst_response_count - last_count
            burst_response_time  = http.burst_response_time_sum - last_response_time_sum

            last_count             = http.burst_response_count
            last_response_time_sum = http.burst_response_time_sum

            sleep_time = (
                1.0 / options[:requests_per_second] * burst_response_count
            ) - burst_response_time

            next if sleep_time <= 0

            print_info "Sleeping for #{sleep_time.round( 3 )} seconds"
            sleep sleep_time

            @@times_slept      += 1
            @@total_time_slept += sleep_time
        end
    end

    def self.info
        {
            name:        'RateLimiter',
            description: %q{
Rate limits HTTP requests
},
            author:      'Bert Hekman <bert@pbwebmedia.com>',
            tags:        %w(http rate limit),
            version:     '0.1',
            options: [
                Options::Int.new( :requests_per_second,
                     description: 'Requests per second.',
                     default: 20
                )
            ]
        }
    end

    def self.times_slept
        @@times_slept
    end

    def self.total_time_slept
        @@total_time_slept
    end
end
