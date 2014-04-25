=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'singleton'
require 'eventmachine'

module Arachni
module Processes

#
# Helper for managing processes.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Manager
    include Singleton

    # @return   [Array<Integer>] PIDs of all running processes.
    attr_reader :pids

    def initialize
        @pids           = []
        @discard_output = true
    end

    #
    # @param    [Integer]   pid
    #   Adds a PID to the {#pids} and detaches the process.
    #
    # @return   [Integer]   `pid`
    #
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

    # Stops the EventMachine reactor.
    def kill_em
        ::EM.stop while ::EM.reactor_running? && sleep( 0.1 )
    rescue
        nil
    end

    # @param    [Block] block   Block to fork and discard its output.
    def quiet_fork( &block )
        self << fork( &discard_output( &block ) )
    end

    # @param    [Block] block
    #   Block to fork and run inside EventMachine's reactor thread -- its output
    #   will be discarded..
    def fork_em( *args, &block )
        self << ::EM.fork_reactor( *args, &discard_output( &block ) )
    end

    # Overrides the default setting of discarding process outputs.
    def preserve_output
        @discard_output = false
    end

    # @param    [Block] block   Block to run silently.
    def discard_output( &block )
        if !block_given?
            @discard_output = true
            return
        end

        proc do
            if @discard_output
                $stdout.reopen( '/dev/null', 'w' )
                $stderr.reopen( '/dev/null', 'w' )
            end
            block.call
        end
    end

    def spawn( executable, options = {} )
        options[:options] = Options.to_h
        encoded_options   = Base64.strict_encode64( Marshal.dump( options ) )
        executable        = "#{Options.paths.lib}processes/executables/#{executable}.rb"

        # It's very, **VERY** important that we use this argument format as it
        # bypasses the OS shell and we can thus count on a 1-to-1 process
        # creation and that the PID we get will be for the actual process.
        Process.spawn( 'ruby', executable, encoded_options )
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
