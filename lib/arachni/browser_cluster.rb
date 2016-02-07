=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

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

    # @return   [Array<Worker>]
    #   Worker pool.
    attr_reader :workers

    # @return   [Integer]
    #   Number of pending jobs.
    attr_reader :pending_job_counter

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
        super()

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

        initialize_workers
    end

    # @return   [String]
    #   Javascript token used to namespace the custom JS environment.
    def javascript_token
        Browser::Javascript::TOKEN
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
            print_debug "Queueing: #{job}"

            notify_on_queue job

            self.class.increment_queued_job_count

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

    # def on_queue( &block )
        # synchronize { @on_queue << block }
    # end

    # def on_job_done( &block )
        # synchronize { @on_job_done << block }
    # end

    # @param    [Page, String, HTTP::Response]  resource
    #   Resource to explore, if given a `String` it will be treated it as a URL
    #   and will be loaded.
    # @param    [Hash]  options
    #   See {Jobs::DOMExploration} accessors.
    # @param    [Block]  block
    #   Callback to be passed the {Job::Result}.
    #
    # @see Jobs::DOMExploration
    # @see #queue
    def explore( resource, options = {}, &block )
        queue(
            Jobs::DOMExploration.new( options.merge( resource: resource ) ),
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
            print_debug "Job done: #{job}"

            notify_on_job_done job

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

            Arachni.collect_young_objects
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
            print_debug "Got job result: #{result}"

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
    #   Pops a job from the queue.
    #
    # @see #queue
    # @private
    def pop
        {} while job_done?( job = @jobs.pop )
        notify_on_pop job
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
            increment_completed_job_count
            add_to_total_job_time( job.time )

            @pending_job_counter  -= 1
            @pending_jobs[job.id] -= 1
            job_done( job ) if @pending_jobs[job.id] <= 0
        end
    end

    # @private
    def callback_for( job )
        @job_callbacks[job.id]
    end

    def increment_queued_job_count
        synchronize do
            self.class.increment_queued_job_count
        end
    end

    def increment_completed_job_count( *args )
        synchronize do
            self.class.increment_completed_job_count( *args )
        end
    end

    def add_to_total_job_time( time )
        synchronize do
            self.class.add_to_total_job_time( time )
        end
    end

    def self.seconds_per_job
        n = (total_job_time / Float( completed_job_count ))
        n.nan? ? 0 : n
    end

    def self.increment_queued_job_count
        @queued_job_count ||= 0
        @queued_job_count += 1
    end

    def self.increment_completed_job_count( increment = 1 )
        @completed_job_count ||= 0
        @completed_job_count += increment
    end

    def self.completed_job_count
        @completed_job_count.to_i
    end

    def self.total_job_time
        @total_job_time.to_i
    end

    def self.add_to_total_job_time( time )
        @total_job_time ||= 0
        @total_job_time += time.to_i
    end

    def self.statistics
        {
            seconds_per_job:     seconds_per_job,
            total_job_time:      total_job_time,
            queued_job_count:    @queued_job_count    || 0,
            completed_job_count: @completed_job_count || 0
        }
    end

    private

    def notify_on_queue( job )
        return if !@on_queue
        @on_queue.call job
    end

    def notify_on_job_done( job )
        return if !@on_job_done

        @on_job_done.call job
    end

    def notify_on_pop( job )
        return if !@on_pop

        @on_pop.call job
    end

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

        @workers = []
        pool_size.times do |i|
            worker = Worker.new(
                master: self,
                width:  Options.browser_cluster.screen_width,
                height: Options.browser_cluster.screen_height
            )
            @workers << worker
            print_status "Spawned ##{i+1} with PID #{worker.browser_pid} " <<
                "[lifeline at PID #{worker.lifeline_pid}]."
        end

        print_status "Initialization completed with #{@workers.size} browsers in the pool."
    end

end
end
