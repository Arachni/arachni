=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'singleton'
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

    # @param    [Integer]   pid
    #   PID of the process to kill.
    def kill( pid )
        Timeout.timeout 10 do
            while sleep 0.1 do
                begin
                    Process.kill( Arachni.windows? ? 'KILL' : 'TERM', pid )

                # Either kill was successful or we don't have enough perms or
                # we hit a reused PID for someone else's process, either way,
                # consider the process gone.
                rescue Errno::ESRCH, Errno::EPERM,
                    # Don't kill ourselves.
                    SignalException

                    @pids.delete pid
                    return
                end
            end
        end
    rescue Timeout::Error
    end

    # @param    [Integer]   pid
    # @return   [Boolean]
    #   `true` if the process is alive, `false` otherwise.
    def alive?( pid )
        # Windows is not big on POSIX so try it its own way if possible.
        if Arachni.windows?
            begin
                alive = false
                wmi = WIN32OLE.connect( 'winmgmts://' )
                processes = wmi.ExecQuery( "select ProcessId from win32_process where ProcessID='#{pid}'" )
                processes.each do |proc|
                    proc.ole_free
                    alive = true
                end
                processes.ole_free
                wmi.ole_free

                return alive
            rescue WIN32OLERuntimeError
            end
        end

        !!(Process.kill( 0, pid ) rescue false)
    end

    # @param    [Array<Integer>]   pids
    #   PIDs of the process to {Arachni::Processes::Manager#kill}.
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
        fork = false if fork.nil?

        stdin      = options.delete(:stdin)
        stdout     = options.delete(:stdout)
        stderr     = options.delete(:stderr)
        new_pgroup = options.delete(:new_pgroup)

        spawn_options = {}

        if new_pgroup
            if Arachni.windows?
                spawn_options[:new_pgroup] = new_pgroup
            else
                spawn_options[:pgroup] = new_pgroup
            end
        end

        spawn_options[:in]     = stdin  if stdin
        spawn_options[:out]    = stdout if stdout
        spawn_options[:err]    = stderr if stderr

        options[:ppid]  = Process.pid

        options[:options] ||= {}
        options[:options]   = Options.to_h.merge( options[:options] )

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
                $stdin = spawn_options[:in] if spawn_options[:in]

                if spawn_options[:out]
                    $stdout = spawn_options[:out]
                elsif discard_output?
                    $stdout.reopen( Arachni.null_device, 'w' )
                end

                if spawn_options[:err]
                    $stderr = spawn_options[:err]
                elsif discard_output?
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
        else
            # It's very, **VERY** important that we use this argument format as
            # it bypasses the OS shell and we can thus count on a 1-to-1 process
            # creation and that the PID we get will be for the actual process.
            pid = Process.spawn(
                RbConfig.ruby,
                RUNNER,
                *(argv + [spawn_options])
            )
        end

        self << pid
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
