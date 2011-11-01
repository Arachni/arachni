=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

#
# Auto adjusts HTTP throughput for maximum network utilization.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.2
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

    def initialize( framework, opts )
        @framework = framework
        @http      = framework.http
    end

    def prepare

        # run for each response as it arrives
        @http.add_on_complete {

            # adjust only after finished bursts
            next if @http.curr_res_cnt == 0 || @http.curr_res_cnt % @http.max_concurrency != 0

            print_debug( "Max concurrency: " + @http.max_concurrency.to_s )
            if( @http.max_concurrency > MIN_CONCURRENCY && @http.average_res_time > HIGH_THRESHOLD ) ||
                @http.max_concurrency > @framework.opts.http_req_limit

                # make sure that @http.max_concurrency >= MIN_CONCURRENCY
                if @http.max_concurrency + STEP_DOWN < MIN_CONCURRENCY
                    step = MIN_CONCURRENCY - @http.max_concurrency
                else
                    step = STEP_DOWN
                end

                print_debug( "Stepping down!: #{step}" )
                @http.max_concurrency!( @http.max_concurrency + step )

            elsif @http.average_res_time < HIGH_THRESHOLD && @http.average_res_time > LOW_THREASHOLD

                print_debug( "Stepping up!: +#{STEP_UP}" )
                @http.max_concurrency!( @http.max_concurrency + STEP_UP )
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
            :version        => '0.1'
        }
    end

end

end
end
