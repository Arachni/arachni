=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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
# Terminal manipulation methods
#
#
# Driver/demo code
#
#
#        require_relative 'terminal'
#        require_relative 'progress_bar'
#
#        include Terminal
#        include ProgressBar
#
#        # clear the screen
#        clear_screen
#
#        start_time = Time.now
#
#        MAX = 5000
#        (1..MAX).each {
#            |i|
#
#            # move the cursor to its home, top-left of the screen.
#            move_to_home
#
#            prog =  i / Float( MAX ) * 100
#
#            reputs "Counting to #{MAX}..."
#            reputs "Progress:   #{prog}%"
#            reputs "Current:    #{i}"
#
#            reputs
#            reprint eta( prog, start_time ) + "    "
#            reputs progress_bar( prog.ceil )
#
#
#            # make sure that everything is sent out on time
#            flush
#            sleep 0.003
#        }
#
module Terminal

    #
    # Clears the line before printing using 'puts'
    #
    # @param    [String]    str  string to output
    #
    def reputs( str = '' )
        reprint str + "\n"
    end

    #
    # Clears the line before printing
    #
    # @param    [String]    str  string to output
    #
    def reprint( str = '' )
        print restr( str )
    end

    def restr( str = '' )
        "\e[0K" + str
    end

    #
    # Clear the bottom of the screen
    #
    def clear_screen
        print "\e[2J"
    end

    #
    # Moves cursor top left to its home
    #
    def move_to_home
        print "\e[H"
    end

    #
    # Flushes the STDOUT buffer
    #
    def flush
        $stdout.flush
    end

    extend self
end

end
end
