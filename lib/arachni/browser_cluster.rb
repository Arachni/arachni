=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

# Real browser driver providing DOM/JS/AJAX support.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class BrowserCluster
    include UI::Output
    include Utilities

    # {BrowserCluster} error namespace.
    #
    # All {BrowserCluster} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Arachni::Error

        # Raised when a method is called after the {BrowserCluster} has been
        # {BrowserCluster#shutdown}.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class AlreadyShutdown < Error
        end

        # Raised when a given {Job} could not be found.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class JobNotFound < Error
        end
    end

    lib = Options.paths.lib
    require lib + 'browser_cluster/peer'
    require lib + 'browser_cluster/job'

    # Load all job types.
    Dir[lib + 'browser_cluster/jobs/*'].each { |j| require j }

    # Holds {BrowserCluster} {Job} types.
    #
    # @see BrowserCluster#queue
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    module Jobs
    end

    DEFAULT_OPTIONS = {
        # Amount of Browsers to keep in the pool and put to work. 6 seems to
        # be the magic number, 1 to go over all elements and generate the workload
        # and 5 to pop the work from the queue and get to it.
        #
        # It's diminishing returns past that point, even with more workload
        # generators and more workers.
        pool_size:    6,

        # Lifetime of each Browser counted in pages.
        time_to_live: 10
    }

    # @return   [Integer]   Amount of browser instances in the pool.
    attr_reader :pool_size

    # @return   [Hash<String, Integer>]
    #   List of crawled URLs with their HTTP codes.
    attr_reader :sitemap

    attr_reader :javascript_token

    # @param    [Hash]  options
    # @option   options [Integer]   :pool_size (5)
    #   Amount of {RPC::Server::Browser browsers} to add to the pool.
    # @option   options [Integer]   :time_to_live (10)
    #   Restricts each browser's lifetime to the given amount of pages.
    #   When that number is exceeded the current process is killed and a new
    #   one is pushed to the pool. Helps prevent memory leak issues.
    #
    # @raise    ArgumentError   On missing `:handler` option.
    def initialize( options = {} )
        DEFAULT_OPTIONS.merge( options ).each do |k, v|
            begin
                send( "#{k}=", try_dup( v ) )
            rescue NoMethodError
                instance_variable_set( "@#{k}".to_sym, v )
            end
        end

        # Used to sync operations between peers per Job#id.
        @skip ||= {}

        # Callbacks for each job per Job#id.
        @job_callbacks = {}

        # Keeps track of the amount of pending jobs distributed across the
        # cluster, by Job#id. Once a job's count reaches 0, it's passed to
        # #job_done.
        @pending_jobs = Hash.new(0)

        # Jobs are off-loaded to disk.
        @jobs = Support::Database::Queue.new

        @sitemap = {}
        @mutex   = Mutex.new

        initialize_browsers

        start
    end

    # @param    [Job]  job
    # @param    [Block]  block Callback to be passed the {Job::Result}.
    #
    # @raise    [AlreadyShutdown]
    # @raise    [Job::Error::AlreadyDone]
    def queue( job, &block )
        fail_if_shutdown

        synchronize do
            @pending_jobs[job.id] += 1
            @job_callbacks[job.id] = block if block

            if !@job_callbacks[job.id]
                fail ArgumentError, "No callback set for job ID #{job.id}."
            end

            @jobs << job
        end

        nil
    end

    # @param    [Page, String, HTTP::Response]  resource
    #   Resource to explore, if given a `String` it will be treated it as a URL
    #   and will be loaded.
    # @param    [Hash]  options See {Jobs::ResourceExploration} accessors.
    # @param    [Block]  block Callback to be passed the {Job::Result}.
    #
    # @see Jobs::ResourceExploration
    # @see #queue
    def explore( resource, options = {}, &block )
        queue(
            Jobs::ResourceExploration.new( options.merge( resource: resource ) ),
            &block
        )
    end

    # @param    [Page, String, HTTP::Response] resource
    #   Resource to load and whose environment to trace, if given a `String` it
    #   will be treated it as a URL and will be loaded.
    # @param    [Hash]  options See {Jobs::TaintTrace} accessors.
    # @param    [Block]  block Callback to be passed the {Job::Result}.
    #
    # @see Jobs::TaintTrace
    # @see #queue
    def trace_taint( resource, options = {}, &block )
        queue( Jobs::TaintTrace.new( options.merge( resource: resource ) ), &block )
    end

    # @param    [Job]  job
    #
    # @return   [Bool]
    #   `true` if the `job` has been marked as finished, `false` otherwise.
    #
    # @raise    [Error::JobNotFound]  Raised when `job` could not be found.
    def job_done?( job )
        synchronize do
            fail_if_job_not_found job
            return false if !@pending_jobs.include?( job.id )
            @pending_jobs[job.id] == 0
        end
    end

    # @param    [Job::Result]  result
    def handle_job_result( result )
        fail_if_shutdown

        synchronize do
            exception_jail( false ) do
                @job_callbacks[result.job.id].call result
            end
        end

        nil
    end

    # @return   [Bool]
    #   `true` if there are no resources to analyze and no running workers.
    def done?
        fail_if_shutdown

        synchronize do
            @jobs.empty? && @browsers[:busy].empty?
        end
    end

    # Blocks until all resources have been analyzed.
    def wait
        fail_if_shutdown

        sleep 0.1 while !done?
        self
    end

    # Shuts the cluster down.
    def shutdown
        return false if !@running

        @running = false

        # Kill the resource consumer thread.
        @worker.kill

        # Clear the temp files used to hold the resources to analyze.
        @jobs.clear

        # Kill the browsers.
        q = Queue.new
        (@browsers[:idle] | @browsers[:busy]).each { |b| b.shutdown { q << nil } }
        pool_size.times { q.pop }

        # Kill our IPC RPC server.
        @servers.map( &:shutdown )

        true
    end

    # Used to sync operations between browser workers.
    #
    # @param    [Integer]   job_id  Job ID.
    # @param    [String]    action  Should the given action be skipped?
    #
    # @raise    [Error::JobNotFound]  Raised when `job` could not be found.
    #
    # @private
    def skip?( job_id, action )
        synchronize do
            skip_lookup_for( job_id ).include? action
        end
    end

    # Used to sync operations between browser workers.
    #
    # @param    [Integer]   job_id  Job ID.
    # @param    [String]    action  Action to skip in the future.
    # @private
    def skip( job_id, action )
        synchronize { skip_lookup_for( job_id ) << action }
    end

    def push_to_sitemap( url, code )
        synchronize { @sitemap[url] = code }
    end

    def alive?
        true
    end

    private

    # @param    [Job]  job
    #   Job to mark as done. Will remove any callbacks or associated {#skip} state.
    def job_done( job )
        synchronize do
            @skip.delete job.id
            @job_callbacks.delete job.id
        end

        nil
    end

    def skip_lookup_for( id )
        @skip[id] ||= Support::LookUp::HashSet.new( hasher: :persistent_hash )
    end

    def fail_if_shutdown
        fail Error::AlreadyShutdown, 'Cluster has been shut down.' if !@running
    end

    def fail_if_job_not_found( job )
        return if @pending_jobs.include?( job.id ) || @job_callbacks.include?( job.id )
        fail Error::JobNotFound, 'Job could not be found.'
    end

    def start
        Thread.abort_on_exception = true

        @running = true
        @worker  = Thread.new do
            while @running do
                sleep 0.05
                next if @jobs.empty?

                synchronize do
                    next if @browsers[:idle].empty?

                    browser = @browsers[:idle].pop
                    @browsers[:busy] << browser

                    job = @jobs.pop
                    browser.run_job( job, cookies: HTTP::Client.cookies ) do
                        @pending_jobs[job.id] -= 1
                        job_done( job ) if @pending_jobs[job.id] == 0

                        move_browser( browser, :busy, :idle )
                    end
                end
            end
        end
    end

    def ipc_handle
        socket = "/tmp/arachni-browser-cluster-#{Utilities.available_port}"
        token = Utilities.generate_token

        @servers ||= []

        server = RPC::Server::Base.new( { server_socket: socket }, token )
        @servers << server

        server.logger.level = ::Logger::Severity::FATAL
        server.add_handler( 'cluster', self )

        RPC::EM.schedule { server.start }
        sleep 0.1 while !File.exists?( socket )

        handler = RPC::RemoteObjectMapper.new(
            RPC::Client::Base.new( Options.instance, socket, token ),
            'cluster'
        )

        wait_till_service_ready handler
        handler
    end

    def move_browser( browser, from_state, to_state )
        synchronize { @browsers[to_state] << @browsers[from_state].delete( browser ) }
    end

    def synchronize( &block )
        @mutex.synchronize( &block )
    end

    def initialize_browsers
        @browsers  = {
            idle: [],
            busy: []
        }

        @javascript_token ||= Utilities.generate_token
        booting_browsers    = []

        pool_size.times do
            booting_browsers << Peer.spawn(
                javascript_token: @javascript_token,
                master:           ipc_handle
            )
        end

        begin
            Timeout.timeout( 10 ) do
                loop do
                    booting_browsers.each do |socket, token|
                        begin
                            b = RPC::Client::BrowserCluster::Peer.new( socket, token )
                            b.alive?
                            booting_browsers.delete( [socket, token] )
                            @browsers[:idle] << b
                        rescue
                        end
                    end
                    break if booting_browsers.empty?
                end
            end
        rescue Timeout::Error
            abort 'BrowserCluster failed to initialize peers in time.'
        end
    end

    def wait_till_service_ready( service )
        begin
            Timeout.timeout( 10 ) do
                while sleep( 0.1 )
                    begin
                        service.alive?
                        break
                    rescue ::RPC::Exceptions::ConnectionError
                    end
                end
            end
        rescue Timeout::Error
            abort 'BrowserCluster never started!'
        end
    end

end
end
