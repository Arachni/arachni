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
# Auto adjusts HTTP throughput for maximum network utilization.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version 0.1.2
#
class AutoThrottle < Arachni::Plugin::Base

    HIGH_THRESHOLD    = 0.9
    MIDDLE_THRESHOLD  = 0.34
    LOW_THREASHOLD    = 0.05

    # easy on the throttle
    STEP_UP      = 1
    # hard on the breaks
    STEP_DOWN    = -3

    MIN_CONCURRENCY = 2

    def prepare
        http = @framework.http

        # run for each response as it arrives
        http.add_on_complete {

            # adjust only after finished bursts
            next if http.curr_res_cnt == 0 || http.curr_res_cnt % http.max_concurrency != 0

            print_debug( "Max concurrency: " + http.max_concurrency.to_s )
            if( http.max_concurrency > MIN_CONCURRENCY && http.average_res_time > HIGH_THRESHOLD ) ||
                http.max_concurrency > @framework.opts.http_req_limit

                # make sure that http.max_concurrency >= MIN_CONCURRENCY
                if http.max_concurrency + STEP_DOWN < MIN_CONCURRENCY
                    step = MIN_CONCURRENCY - http.max_concurrency
                else
                    step = STEP_DOWN
                end

                print_debug( "Stepping down!: #{step}" )
                http.max_concurrency!( http.max_concurrency + step )

            elsif http.average_res_time < HIGH_THRESHOLD && http.average_res_time > LOW_THREASHOLD

                print_debug( "Stepping up!: +#{STEP_UP}" )
                http.max_concurrency!( http.max_concurrency + STEP_UP )
            end
        }

    end

    def self.distributable?
        true
    end

    def self.info
        {
            :name           => 'AutoThrottle',
            :description    => %q{Monitors HTTP response times and automatically
                throttles the request concurrency in order to maintain stability
                and prevent from killing the server.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :tags           => [ 'meta' ],
            :version        => '0.1.2'
        }
    end

end

end
end
