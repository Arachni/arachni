=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# get some basics from the CLI UI's output interface
require Arachni::Options.dir['lib'] + 'ui/cli/output'

module Arachni

module UI

#
# RPC Output module
#
# It basically classifies and buffers all system messages until it's time to
# flush the buffer and send them over the wire.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Output

    class << self
        alias :old_reset_output_options :reset_output_options
    end

    def self.reset_output_options
        old_reset_output_options
        @@output_buffer_cap = 30
        @@output_buffer ||= []
    end

    reset_output_options

    #
    # Empties the output buffer and returns all messages.
    #
    # Messages are classified by their type.
    #
    # @return   [Array<Hash>]
    #
    def flush_buffer
        buf = @@output_buffer.dup
        @@output_buffer.clear
        buf
    end

    def set_buffer_cap( cap )
        @@output_buffer_cap = cap
    end

    def uncap_buffer
        @@output_buffer_cap = nil
    end

    # Prints an error message
    #
    # It ignores all flags, error messages will be output under all
    # circumstances.
    #
    # @param    [String]    str    error string
    #
    def print_error( str = '' )
        log_error( str )
        push_to_output_buffer( :error => str )
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
        push_to_output_buffer( bad: str )
    end

    # Prints a status message
    #
    # Obeys {@@only_positives}
    #
    # @see #only_positives?
    # @see #only_positives
    #
    # @param    [String]    str
    #
    def print_status( str = '' )
        return if only_positives?
        push_to_output_buffer( status: str )
    end

    # Prints an info message
    #
    # Obeys {@@only_positives}
    #
    # @see #only_positives?
    # @see #only_positives
    #
    # @param    [String]    str
    #
    def print_info( str = '' )
        return if only_positives?
        push_to_output_buffer( info: str )
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
        push_to_output_buffer( ok: str )
    end

    # Prints a debugging message
    #
    # Obeys {@@debug}
    #
    # @see #debug?
    # @see #debug
    #
    # @param    [String]    str
    #
    def print_debug( str = '' )
        return if !debug?

        if reroute_to_file?
            push_to_output_buffer( debug: str )
        else
            print_color( '[!]', 36, str, $stderr )
        end
    end

    # Prints a verbose message
    #
    # Obeys {@@verbose}
    #
    # @see #verbose?
    # @see #verbose
    #
    # @param    [String]    str
    #
    def print_verbose( str = '' )
        return if !verbose?
        push_to_output_buffer( verbose: str )
    end

    # Prints a line of message
    #
    # Obeys {@@only_positives}
    #
    # @see #only_positives?
    # @see #only_positives
    #
    # @param    [String]    str
    #
    def print_line( str = '' )
        return if only_positives?
        push_to_output_buffer( line: str )
    end

    def reroute_to_file( file )
        @@reroute_to_file = file
    end

    def reroute_to_file?
        @@reroute_to_file
    end

    private

    def push_to_output_buffer( msg )
        if file = @@reroute_to_file
            File.open( file, 'a+' ) do |f|
                type = msg.keys[0]
                str  = msg.values[0]
                next if str.empty?

                f.write( "[#{Time.now.asctime}] [#{type}]  #{str}\n" )
            end
        else
            @@output_buffer << msg
            if @@output_buffer_cap.is_a?( Integer )
                @@output_buffer.slice!( (@@output_buffer.size - @@output_buffer_cap)..@@output_buffer.size )
            end
        end
    end

    extend self

end

end
end
