=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module MetaModules

#
# Auto adjusts HTTP throughput for maximum network utilization.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Throughput < Base

    HIGH_THRESHOLD = 0.5
    LOW_THRESHOLD  = 0.1
    STEP      = 1
    MIN_CONCURRENCY = 5

    def initialize( framework )
        @http = framework.http
    end

    def prepare
        # run for each response as it arrives
        @http.on_complete {

            # adjust only after finished bursts
            next if @http.curr_res_cnt == 0 || @http.curr_res_cnt % @http.max_concurrency != 0

            print_debug( "Max concurrency: " + @http.max_concurrency.to_s )
            if @http.average_res_time > HIGH_THRESHOLD && @http.max_concurrency > MIN_CONCURRENCY

                print_debug( "Stepping down!: -#{STEP}" )
                @http.max_concurrency!( @http.max_concurrency - STEP )

            elsif @http.average_res_time < LOW_THRESHOLD

                print_debug( "Stepping up!: +#{STEP}" )
                @http.max_concurrency!( @http.max_concurrency + STEP )
            end
        }
    end

end

end
end
