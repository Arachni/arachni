=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'singleton'

module Arachni
module Processes

# Helper for managing processes.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Manager
    include Singleton

    RUNNER = "#{File.dirname( __FILE__ )}/executables/base.rb"

    # @return   [Array<Integer>] PIDs of all running processes.
    attr_reader :pids

    def initialize
        @pids           = []
        @discard_output = true
    end

    # @param    [Integer]   pid
    #   Adds a PID to the {#pids} and detaches the process.
    #
    # @return   [Integer]   `pid`
    def <<( pid )
        @pids << pid
        Process.detach pid
        pid
    end

    # @param    [Integer]   pid PID of the process to kill.
    def kill( pid )
        while sleep 0.1 do
            begin
                # I'd rather this be an INT but WEBrick's INT traps write to the
                # Logger and multiple INT signals force it to write to a closed
                # logger and crash.
                Process.kill( 'KILL', pid )
            rescue Errno::ESRCH
                @pids.delete pid
                return
            end
        end
    end

    # @param    [Array<Integer>]   pids PIDs of the process to {#kill}.
    def kill_many( pids )
        pids.each { |pid| kill pid }
    end

    # Kills all {#pids processes}.
    def killall
        kill_many @pids.dup
        @pids.clear
    end

    # Stops the Reactor.
    def kill_reactor
        Reactor.stop
    rescue
        nil
    end

    # Overrides the default setting of discarding process outputs.
    def preserve_output
        @discard_output = false
    end

    def preserve_output?
        !discard_output?
    end

    def discard_output
        @discard_output = true
    end

    def discard_output?
        @discard_output
    end

    def spawn( executable, options = {} )
        options[:options] ||= {}
        options[:options]   = Options.to_h.merge( options[:options] )

        encoded_options = Base64.strict_encode64( Marshal.dump( options ) )
        executable      = "#{Options.paths.executables}/#{executable}.rb"

        # It's very, **VERY** important that we use this argument format as it
        # bypasses the OS shell and we can thus count on a 1-to-1 process
        # creation and that the PID we get will be for the actual process.
        pid = Process.spawn( 'ruby', RUNNER, executable, encoded_options )
        self << pid
        pid
    end

    def self.method_missing( sym, *args, &block )
        if instance.respond_to?( sym )
            instance.send( sym, *args, &block )
        elsif
        super( sym, *args, &block )
        end
    end

    def self.respond_to?( m )
        super( m ) || instance.respond_to?( m )
    end

end

end
end
