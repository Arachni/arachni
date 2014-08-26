=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'monitor'

module Arachni

# Real browser driver providing DOM/JS/AJAX support.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class BrowserCluster
    include UI::Output
    include Utilities

    personalize_output

    # {BrowserCluster} error namespace.
    #
    # All {BrowserCluster} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::Error

        # Raised when a method is called after the {BrowserCluster} has been
        # {BrowserCluster#shutdown}.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class AlreadyShutdown < Error
        end

        # Raised when a given {Job} could not be found.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class JobNotFound < Error
        end
    end

    lib = Options.paths.lib
    require lib + 'browser_cluster/worker'
    require lib + 'browser_cluster/job'

    # Holds {BrowserCluster} {Job} types.
    #
    # @see BrowserCluster#queue
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    module Jobs
    end

    # Load all job types.
    Dir[lib + 'browser_cluster/jobs/*'].each { |j| require j }

    # @return   [Integer]
    #   Amount of browser instances in the pool.
    attr_reader :pool_size

    # @return   [Hash<String, Integer>]
    #   List of crawled URLs with their HTTP codes.
    attr_reader :sitemap

    # @return   [String]
    #   Javascript token used to namespace the custom JS environment.
    attr_reader :javascript_token

    # @return   [Array<Worker>]
    #   Worker pool.
    attr_reader :workers

    # @return   [Integer]
    #   Number of pending jobs.
    attr_reader :pending_job_counter

    attr_reader :consumed_pids

    # @param    [Hash]  options
    # @option   options [Integer]   :pool_size (5)
    #   Amount of {Worker browsers} to add to the pool.
    # @option   options [Integer]   :time_to_live (10)
    #   Restricts each browser's lifetime to the given amount of pages.
    #   When that number is exceeded the current process is killed and a new
    #   one is pushed to the pool. Helps prevent memory leak issues.
    #
    # @raise    ArgumentError   On missing `:handler` option.
    def initialize( options = {} )
        {
            pool_size: Options.browser_cluster.pool_size
        }.merge( options ).each do |k, v|
            begin
                send( "#{k}=", try_dup( v ) )
            rescue NoMethodError
                instance_variable_set( "@#{k}".to_sym, v )
            end
        end

        # Used to sync operations between workers per Job#id.
        @skip_states_per_job = {}

        # Callbacks for each job per Job#id. We need to keep track of this
        # here because jobs are serialized and off-loaded to disk and thus can't
        # contain Block or Proc objects.
        @job_callbacks = {}

        # Keeps track of the amount of pending jobs distributed across the
        # cluster, by Job#id. Once a job's count reaches 0, it's passed to
        # #job_done.
        @pending_jobs = Hash.new(0)
        @pending_job_counter = 0

        # Jobs are off-loaded to disk.
        @jobs = Support::Database::Queue.new

        # Worker pool holding BrowserCluster::Worker instances.
        @workers     = []

        # Stores visited resources from all workers.
        @sitemap     = {}
        @mutex       = Monitor.new
        @done_signal = Queue.new

        # Javascript token to share across all workers.
        @javascript_token = Utilities.generate_token

        @consumed_pids = []
        initialize_workers
    end

    # @note Operates in non-blocking mode.
    #
    # @param    [Block] block
    #   Block to which to pass a {Worker} as soon as one is available.
    def with_browser( &block )
        queue( Jobs::BrowserProvider.new, &block )
    end

    # @param    [Job]  job
    # @param    [Block]  block
    #   Callback to be passed the {Job::Result}.
    #
    # @raise    [AlreadyShutdown]
    # @raise    [Job::Error::AlreadyDone]
    def queue( job, &block )
        fail_if_shutdown
        fail_if_job_done job

        @done_signal.clear

        synchronize do
            @pending_job_counter  += 1
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
    # @param    [Hash]  options
    #   See {Jobs::ResourceExploration} accessors.
    # @param    [Block]  block
    #   Callback to be passed the {Job::Result}.
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
    # @param    [Hash]  options
    #   See {Jobs::TaintTrace} accessors.
    # @param    [Block]  block
    #   Callback to be passed the {Job::Result}.
    #
    # @see Jobs::TaintTrace
    # @see #queue
    def trace_taint( resource, options = {}, &block )
        queue( Jobs::TaintTrace.new( options.merge( resource: resource ) ), &block )
    end

    # @param    [Job]  job
    #   Job to mark as done. Will remove any callbacks and associated
    #   {Worker} states.
    def job_done( job )
        synchronize do
            if !job.never_ending?
                @skip_states_per_job.delete job.id
                @job_callbacks.delete job.id
            end

            @pending_job_counter -= @pending_jobs[job.id]
            @pending_jobs[job.id] = 0

            if @pending_job_counter <= 0
                @pending_job_counter = 0
                @done_signal << nil
            end
        end

        true
    end

    # @param    [Job]  job
    #
    # @return   [Bool]
    #   `true` if the `job` has been marked as finished, `false` otherwise.
    #
    # @raise    [Error::JobNotFound]  Raised when `job` could not be found.
    def job_done?( job, fail_if_not_found = true )
        return false if job.never_ending?

        synchronize do
            fail_if_job_not_found job if fail_if_not_found
            return false if !@pending_jobs.include?( job.id )
            @pending_jobs[job.id] == 0
        end
    end

    # @param    [Job::Result]  result
    #
    # @private
    def handle_job_result( result )
        return if @shutdown
        return if job_done? result.job

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
        @pending_job_counter == 0
    end

    # Blocks until all resources have been analyzed.
    def wait
        fail_if_shutdown
        @done_signal.pop if !done?
        self
    end

    # Shuts the cluster down.
    def shutdown( wait = true )
        @shutdown = true

        # Clear the jobs -- don't forget this, it also removes the disk files for
        # the contained items.
        @jobs.clear

        # Kill the browsers.
        @workers.each { |b| exception_jail( false ) { b.shutdown wait } }
        @workers.clear

        # Very important to leave these for last, they may contain data
        # necessary to cleanly handle interrupted jobs.
        @job_callbacks.clear
        @skip_states_per_job.clear
        @pending_jobs.clear

        true
    end

    # @return    [Job]
    # #Pops a job from the queue.
    #
    # @see #queue
    # @private
    def pop
        {} while job_done?( job = @jobs.pop )
        job
    end

    # Used to sync operations between browser workers.
    #
    # @param    [Integer]   job_id
    #   Job ID.
    # @param    [String]    state
    #   Should the given state be skipped?
    #
    # @raise    [Error::JobNotFound]
    #   Raised when `job` could not be found.
    #
    # @private
    def skip_state?( job_id, state )
        synchronize do
            skip_states( job_id ).include? state
        end
    end

    # Used to sync operations between browser workers.
    #
    # @param    [Integer]   job_id
    #   Job ID.
    # @param    [String]    state
    #   State to skip in the future.
    #
    # @private
    def skip_state( job_id, state )
        synchronize { skip_states( job_id ) << state }
    end

    # @private
    def push_to_sitemap( url, code )
        synchronize { @sitemap[url] = code }
    end

    # @private
    def update_skip_states( id, lookups )
        synchronize { skip_states( id ).merge lookups }
    end

    # @private
    def skip_states( id )
        synchronize do
            @skip_states_per_job[id] ||=
                Support::LookUp::HashSet.new( hasher: :persistent_hash )
        end
    end

    # @private
    def decrease_pending_job( job )
        synchronize do
            @pending_job_counter  -= 1
            @pending_jobs[job.id] -= 1
            job_done( job ) if @pending_jobs[job.id] <= 0
        end
    end

    # @private
    def callback_for( job )
        @job_callbacks[job.id]
    end

    private

    def fail_if_shutdown
        fail Error::AlreadyShutdown, 'Cluster has been shut down.' if @shutdown
    end

    def fail_if_job_done( job )
        return if !job_done?( job, false )
        fail Job::Error::AlreadyDone, 'Job has been marked as done.'
    end

    def fail_if_job_not_found( job )
        return if @pending_jobs.include?( job.id ) || @job_callbacks.include?( job.id )
        fail Error::JobNotFound, 'Job could not be found.'
    end

    def synchronize( &block )
        @mutex.synchronize( &block )
    end

    def initialize_workers
        print_status "Initializing #{pool_size} browsers..."

        # Calculate maximum HTTP connection concurrency for each worker based on
        # the HTTP request concurrency setting of the framework.
        #
        # Ideally, we'd throttle the collective connections of all browsers
        # for optimal concurrency, but that would require all browsers sharing
        # the same proxy which would make things **really** dirty and complicated
        # so let's avoid that for as long as possible.
        #concurrency = [(Options.http.request_concurrency / pool_size).to_i, 1].max

        @workers = []
        workers  = Queue.new

        pool_size.times do
            Thread.new do
                workers << Worker.new(
                    javascript_token: @javascript_token,
                    master:           self,
                    width:            Options.browser_cluster.screen_width,
                    height:           Options.browser_cluster.screen_height
                    #concurrency:      concurrency
                )
            end
        end

        pool_size.times do
            @workers << workers.pop.tap { |b| @consumed_pids << b.pid }
        end
        @consumed_pids.compact!

        print_status "Initialization completed with #{@workers.size} browsers in the pool."
    end

end
end
