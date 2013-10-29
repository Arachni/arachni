=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

module UI

#
# CLI Output module
#
# Provides a command line output interface to the framework.<br/>
# All UIs should provide an Arachni::UI::Output module with these methods.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Output

    def self.reset_output_options
        # verbosity flag
        #
        # if it's on verbose messages will be enabled
        @@verbose = false

        # debug flag
        #
        # if it's on debugging messages will be enabled
        @@debug   = false

        @@mute = false

        # only_positives flag
        #
        # if it's on status messages will be disabled
        @@only_positives  = false

        @@reroute_to_file = false

        @@opened = false

        @@error_logfile = 'error.log'
    end

    reset_output_options

    def set_error_logfile( logfile )
        @@error_logfile = logfile
    end

    def error_logfile
        @@error_logfile
    end

    # Prints an error message
    #
    # It ignores all flags, error messages will be output under all
    # circumstances.
    #
    # @param    [String]    str
    #
    def print_error( str = '' )
        print_color( '[-]', 31, str, $stderr, true )
        log_error( str )
    end

    def log_error( str = '' )
        File.open( @@error_logfile, 'a' ) do |f|
            if !@@opened
                f.puts
                f.puts "#{Time.now} " + ( "-" * 80 )

                begin
                    h = {}
                    ENV.each { |k, v| h[k] = v }
                    f.puts 'ENV:'
                    f.puts h.to_yaml

                    f.puts "-" * 80

                    f.puts 'OPTIONS:'
                    f.puts Arachni::Options.instance.to_yaml
                rescue
                end

                f.puts "-" * 80
            end
            print_color( "[#{Time.now}]", 31, str, f, true )
        end

        @@opened = true
    end

    #
    # Same as print_error but the message won't be printed to stderr.
    #
    # Used mainly to draw attention.
    #
    # @param    [String]    str
    # @param    [Bool]    unmute    override mute
    #
    def print_bad( str = '', unmute = false )
        return if muted? && !unmute
        print_color( '[-]', 31, str, $stdout, unmute )
    end

    # Prints a status message
    #
    # Obeys {@@only_positives}
    #
    # @see #only_positives?
    # @see #only_positives!
    #
    # @param    [String]    str
    # @param    [Bool]    unmute    override mute
    #
    def print_status( str = '', unmute = false )
        return if only_positives?
        print_color( '[*]', 34, str, $stdout, unmute )
    end

    # Prints an info message
    #
    # Obeys {@@only_positives}
    #
    # @see #only_positives?
    # @see #only_positives!
    #
    # @param    [String]    str
    # @param    [Bool]    unmute    override mute
    #
    def print_info( str = '', unmute = false )
        return if only_positives?
        print_color( '[~]', 30, str, $stdout, unmute )
    end

    # Prints a good message, something that went very very right,
    # like the discovery of a vulnerability
    #
    # Disregards all flags.
    #
    # @param    [String]    str
    # @param    [Bool]    unmute    override mute
    #
    def print_ok( str = '', unmute = false )
        print_color( '[+]', 32, str, $stdout, unmute )
    end

    # Prints a debugging message
    #
    # Obeys {@@debug}
    #
    # @see #debug?
    # @see #debug
    #
    # @param    [String]    str
    # @param    [Bool]    unmute    override mute
    #
    def print_debug( str = '', unmute = false )
        return if !debug?
        print_color( '[!]', 36, str, $stderr, unmute )
    end

    # Pretty prints an object, used for debugging,
    # needs some improvement but it'll do for now
    #
    # Obeys {@@debug}
    #
    # @see #debug?
    # @see #debug
    #
    # @param    [Object]    obj
    #
    def print_debug_pp( obj = nil )
        return if !debug?
        pp obj
    end

    # Prints the backtrace of an exception
    #
    # Obeys {@@debug}
    #
    # @see #debug?
    # @see #debug
    #
    # @param    [Exception] e
    #
    def print_debug_backtrace( e )
        return if !debug?
        e.backtrace.each{ |line| print_debug( line ) }
    end

    def print_error_backtrace( e )
        e.backtrace.each{ |line| print_error( line ) }
    end


    # Prints a verbose message
    #
    # Obeys {@@verbose}
    #
    # @see #verbose?
    # @see #verbose!
    #
    # @param    [String]    str
    # @param    [Bool]    unmute    override mute
    #
    def print_verbose( str = '', unmute = false )
        return if !verbose?
        print_color( '[v]', 37, str, $stdout, unmute )
    end

    # Prints a line of message
    #
    # Obeys {@@only_positives}
    #
    # @see #only_positives?
    # @see #only_positives!
    #
    # @param    [String]    str
    # @param    [Bool]    unmute    override mute
    #
    def print_line( str = '', unmute = false )
        return if only_positives?
        return if muted? && !unmute

        # we may get IO errors...freaky stuff...
        begin
            puts str
        rescue
        end
    end

    # Sets the {@@verbose} flag to true
    #
    # @see #verbose?
    #
    # @return    [void]
    #
    def verbose
        @@verbose = true
    end

    # Returns the {@@verbose} flag
    #
    # @see #verbose
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
    def debug_on
        @@debug = true
    end
    alias :debug :debug_on

    def debug_off
        @@debug = false
    end

    # Returns the {@@debug} flag
    #
    # @see #debug
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
    def only_positives
        @@only_positives = true
    end

    def disable_only_positives
        @@only_positives = false
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

    def mute
        @@mute = true
    end

    def unmute
        @@mute = false
    end

    def muted?
        @@mute
    end

    private

    def intercept_print_message( message )
        message
    end

    # Prints a message prefixed with a colored sign.
    #
    # Disregards all flags.
    #
    # @param    [String]    sign
    # @param    [Integer]   color     shell color number
    # @param    [String]    string    the string to output
    # @param    [IO]        out        output stream
    # @param    [Bool]      unmute    override mute
    #
    # @return    [void]
    #
    def print_color( sign, color, string, out = $stdout, unmute = false )
        return if muted? && !unmute

        str = intercept_print_message( string )
        #str = add_resource_usage_statistics( str )

        # we may get IO errors...freaky stuff...
        begin
            if out.tty?
                out.print "\033[1;#{color.to_s}m #{sign}\033[1;00m #{str}\n"
            else
                out.print "#{sign} #{str}\n"
            end
        rescue
        end
    end

    def add_resource_usage_statistics( message )
        require 'sys/proctable'

        procinfo = ::Sys::ProcTable.ps( Process.pid )
        pctcpu   = procinfo[:pctcpu]
        pctmem   = procinfo[:pctmem]
        rss      = procinfo[:rss]
        @rss   ||= rss

        # Change in RAM consumption in MB | Total RAM consumption in MB (RAM %) |
        # CPU usage % | Amount of Typhoeus::Request - Typhoeus::Response objects in RAM |
        # Proc objects in RAM
        sprintf( '%7.4f | %8.4f (%5.1f%%) | %5.1f%% | %3i - %3i | %5i | ',
                rss_to_mb(rss - @rss), rss_to_mb(rss), pctmem, pctcpu,
                ::ObjectSpace.each_object( ::Typhoeus::Request ){},
                ::ObjectSpace.each_object( ::Typhoeus::Response ){},
                ::ObjectSpace.each_object( ::Proc ){}) + message
    ensure
        @rss = rss
    end

    def rss_to_mb( rss )
        rss * 4096.0 / 1024.0 / 1024.0
    end

    extend self

end

end
end
