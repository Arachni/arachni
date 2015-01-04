=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'singleton'
require 'childprocess'
require 'arachni/reactor'

module Arachni
module Processes

# Helper for managing processes.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Manager
    include Singleton

    RUNNER = "#{File.dirname( __FILE__ )}/executables/base.rb"

    # @return   [Array<Integer>] PIDs of all running processes.
    attr_reader :pids

    def initialize
        @processes      = {}
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
        if (process = @processes[pid])
            return process.stop
        end

        Timeout.timeout 10 do
            while sleep 0.1 do
                begin
                    Process.kill( Gem.win_platform? ? 'QUIT' : 'KILL', pid )
                rescue Errno::ESRCH
                    @pids.delete pid
                    return
                end
            end
        end
    rescue Timeout::Error
    end

    # @param    [Array<Integer>]   pids
    #   PIDs of the process to {Arachni::Processes::Manager#kill}.
    def kill_many( pids )
        pids.each { |pid| kill pid }
    end

    # Kills all {#pids processes}.
    def killall
        kill_many @processes.keys
        @processes.clear
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

    # @param    [String]    executable
    #   Name of the executable Ruby script found in {OptionGroups::Paths#executables}
    #   without the '.rb' extension.
    # @param    [Hash]  options
    #   Options to pass to the script -- can be retrieved from `$options`.
    #
    # @return   [Integer]
    #   PID of the process.
    def spawn( executable, options = {} )
        fork = options.delete(:fork)
        fork = true if fork.nil?

        options[:options] ||= {}
        options[:options] = Options.to_h.merge( options[:options] )

        # Paths are not included in RPC nor Hash representations as they're
        # considered local, in this case though they're necessary to provide
        # the same environment the processes.
        options[:options][:paths] = Options.paths.to_h

        executable      = "#{Options.paths.executables}/#{executable}.rb"
        encoded_options = Base64.strict_encode64( Marshal.dump( options ) )
        argv            = [executable, encoded_options]

        # Process.fork is faster, less stressful to the CPU and lets the parent
        # and child share the same RAM due to copy-on-write support on Ruby 2.0.0.
        # It is, however, not available when running on Windows nor JRuby so
        # have a fallback ready.
        if fork && Process.respond_to?( :fork )
            pid = Process.fork do
                if discard_output?
                    $stdout.reopen( Arachni.null_device, 'w' )
                    $stderr.reopen( Arachni.null_device, 'w' )
                end

                # Careful, Framework.reset will remove objects from Data
                # structures which off-load to disk, those files however belong
                # to our parent and should not be touched, thus, we remove
                # any references to them.
                Data.framework.page_queue.disk.clear
                Data.framework.url_queue.disk.clear
                Data.framework.rpc.distributed_page_queue.disk.clear

                # Provide a clean slate.
                Framework.reset
                Reactor.stop

                ARGV.replace( argv )
                load RUNNER
            end

            @processes[pid] = nil
        else
            process = ChildProcess.build( RbConfig.ruby, RUNNER, *argv )
            process.detach = true
            process.start

            begin
                pid = process.pid

            # For JRuby on MS Windows, make up our own PID.
            rescue NotImplementedError
                loop do
                    pid = rand(99999)
                    break if !@processes.include?( pid )
                end
            end
            @processes[pid] = process
        end

        pid
    end

    def self.method_missing( sym, *args, &block )
        if instance.respond_to?( sym )
            instance.send( sym, *args, &block )
        else
            super( sym, *args, &block )
        end
    end

    def self.respond_to?( m )
        super( m ) || instance.respond_to?( m )
    end

end

end
end
