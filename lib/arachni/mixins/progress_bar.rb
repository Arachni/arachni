=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

module Mixins

#
# Progress bar and ETA methods
#
module ProgressBar

    #
    # Formats elapsed time to hour:min:sec
    #
    def format_time( t )
        t = t.to_i rescue 0
        sec = t % 60
        min = ( t / 60 ) % 60
        hour = t / 3600
        sprintf( "%02d:%02d:%02d", hour, min, sec )
    end

    #
    # Calculates ETA (Estimated Time of Arrival) based on current progress
    # and the start time of the operation.
    #
    # @param    [Float]   prog         current progress percentage
    # @param    [Time]   start_time    start time of the operation
    #
    # @return   [String]    ETA: hour:min:sec
    #
    def eta( prog, start_time )
        @last_prog ||= prog
        @last_eta  ||= "--:--:--"

        if @last_prog != prog
            elapsed = Time.now - start_time
            eta     = elapsed * 100 / prog - elapsed
            eta_str = format_time( eta )
        else
            eta_str = @last_eta
            prog = @last_prog
        end

        @last_prog = prog
        @last_eta  = eta_str
    end

    #
    # Returns an ASCII progress bar based on the current progress percentage
    #
    # @param    [Float]     progress     progress percentage
    # @param    [Integer]   width        width of the progressbar in characters
    #
    # @return   [String]    70% [=======>  ] 100%
    #
    def progress_bar( progress, width = 100 )
        progress = 100.0 if progress > 100

        bar_prog = progress * width / 100

        bar  = '=' * ( bar_prog.ceil - 1 ).abs + '>'
        pad = ( width - bar_prog )
        bar += ' ' * pad if pad > 0

        "#{progress}% [#{bar}] 100% "
    end

    extend self
end

end
end
