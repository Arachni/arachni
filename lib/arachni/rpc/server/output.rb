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

# get some basics from the CLI UI's output interface
require Options.instance.dir['lib'] + 'ui/cli/output'

module UI

#
# RPC deamon Output module
#
# It basically classifies and buffers all system messages until it's time to
# flush the buffer and send them over the wire.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#
module Output

    # verbosity flag
    #
    # if it's on verbose messages will be enabled
    @@verbose = false

    # debug flag
    #
    # if it's on debugging messages will be enabled
    @@debug   = false

    # only_positives flag
    #
    # if it's on status messages will be disabled
    @@only_positives  = false

    @@reroute_to_file = false

    @@buffer_cap = 30

    @@buffer ||= []

    #
    # Empties the output buffer and returns all messages.
    #
    # Messages are classified by their type.
    #
    # @return   [Array<Hash>]
    #
    def flush_buffer
        buf = @@buffer.dup
        @@buffer.clear
        return buf
    end

    def buffer( msg )
        if file = @@reroute_to_file
            File.open( file, 'a+' ) {
                |f|

                type = msg.keys[0]
                str  = msg.values[0]
                next if str.empty?

                f.write( "[#{Time.now.asctime}] [#{type}]  #{str}\n" )
            }
        else
            @@buffer << msg
            if @@buffer_cap.is_a? Integer
                @@buffer.slice!( (@@buffer.size - @@buffer_cap)..@@buffer.size  )
            end
        end
    end

    def uncap_buffer!
        @@buffer_cap = nil
    end

    # Prints an error message
    #
    # It ignores all flags, error messages will be output under all
    # circumstances.
    #
    # @param    [String]    str    error string
    # @return    [void]
    #
    def print_error( str = '' )
        buffer( :error => str )
        print_color( '[-]', 31, str, $stderr )
    end
    def print_error_backtrace( e )
        e.backtrace.each { |line| print_error( line ) }
    end

    #
    # Same as print_error but the message won't be printed to stderr.
    #
    # Used mainly to draw attention to something that didn't behave as expected
    # rather than display an actual error.
    #
    # @param    [String]    str
    #
    def print_bad( str = '' )
        buffer( :bad => str )
    end

    # Prints a status message
    #
    # Obeys {@@only_positives}
    #
    # @see #only_positives?
    # @see #only_positives!
    #
    # @param    [String]    str
    # @return    [void]
    #
    def print_status( str = '' )
        if @@only_positives then return end
        buffer( :status => str )
    end

    # Prints an info message
    #
    # Obeys {@@only_positives}
    #
    # @see #only_positives?
    # @see #only_positives!
    #
    # @param    [String]    str
    # @return    [void]
    #
    def print_info( str = '' )
        if @@only_positives then return end
        buffer( :info => str )
    end

    # Prints a good message, something that went very very right,
    # like the discovery of a vulnerability
    #
    # Disregards all flags.
    #
    # @param    [String]    str
    # @return    [void]
    #
    def print_ok( str = '' )
        buffer( :ok => str )
    end

    # Prints a debugging message
    #
    # Obeys {@@debug}
    #
    # @see #debug?
    # @see #debug!
    #
    # @param    [String]    str
    # @return    [void]
    #
    def print_debug( str = '' )
        if !@@debug then return end

        if reroute_to_file?
            buffer( :debug => str )
        else
            print_color( '[!]', 36, str, $stderr )
        end
    end

    # Pretty prints an object, used for debugging,
    # needs some improvement but it'll do for now
    #
    # Obeys {@@debug}
    #
    # @see #debug?
    # @see #debug!
    #
    # @param    [Object]
    # @return    [void]
    #
    def print_debug_pp( obj = nil )
        if !@@debug then return end
        pp obj
    end

    # Prints the backtrace of an exception
    #
    # Obeys {@@debug}
    #
    # @see #debug?
    # @see #debug!
    #
    # @param    [Exception]
    # @return    [void]
    #
    def print_debug_backtrace( e = nil )
        if !@@debug then return end
        e.backtrace.each{ |line| print_debug( line ) }
    end

    # Prints a verbose message
    #
    # Obeys {@@verbose}
    #
    # @see #verbose?
    # @see #verbose!
    #
    # @param    [String]    str
    # @return    [void]
    #
    def print_verbose( str = '' )
        if !@@verbose then return end
        buffer( :verbose => str )
    end

    # Prints a line of message
    #
    # Obeys {@@only_positives}
    #
    # @see #only_positives?
    # @see #only_positives!
    #
    # @param    [String]    str
    # @return    [void]
    #
    def print_line( str = '' )
        if @@only_positives then return end
        buffer( :line => str )
    end

    # Sets the {@@verbose} flag to true
    #
    # @see #verbose?
    #
    # @return    [void]
    #
    def verbose!
        @@verbose = true
    end

    # Returns the {@@verbose} flag
    #
    # @see #verbose!
    #
    # @return    [Bool]    @@verbose
    #
    def verbose?
        @@verbose
    end

    # Sets the {@@debug} flag to true
    #
    # @see #debug?
    #
    # @return    [void]
    #
    def debug!
        @@debug = true
    end

    # Returns the {@@debug} flag
    #
    # @see #debug!
    #
    # @return    [Bool]    @@debug
    #
    def debug?
        @@debug
    end

    # Sets the {@@only_positives} flag to true
    #
    # @see #only_positives?
    #
    # @return    [void]
    #
    def only_positives!
        @@only_positives = true
    end

    # Returns the {@@only_positives} flag
    #
    # @see #only_positives!
    #
    # @return    [Bool]    @@only_positives
    #
    def only_positives?
        @@only_positives
    end

    def reroute_to_file( file )
        @@reroute_to_file = file
    end

    def reroute_to_file?
        @@reroute_to_file
    end

    extend self

end

end
end
