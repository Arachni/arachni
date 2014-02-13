=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'monitor'

module Arachni

# Real browser driver providing DOM/JS/AJAX support.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class BrowserCluster
    include UI::Output
    include Utilities

    personalize_output

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

    attr_reader :consumed_pids

    # @return   [String]
    #   Javascript token used to namespace the custom JS environment.
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
        @mutex   = Monitor.new

        initialize_browsers
    end

    # @return    [Job]  Pops a job from the queue.
    # @see #queue
    def pop
        job = @jobs.pop
        job = pop if job_done? job
        job
    end

    # @param    [Job]  job
    # @param    [Block]  block Callback to be passed the {Job::Result}.
    #
    # @raise    [AlreadyShutdown]
    # @raise    [Job::Error::AlreadyDone]
    def queue( job, &block )
        fail_if_shutdown
        fail_if_job_done job

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
    #   Job to mark as done. Will remove any callbacks and associated {#skip} state.
    def job_done( job )
        synchronize do
            @skip.delete job.id
            @job_callbacks.delete job.id
            @pending_jobs[job.id] = 0
        end

        nil
    end

    # @param    [Job]  job
    #
    # @return   [Bool]
    #   `true` if the `job` has been marked as finished, `false` otherwise.
    #
    # @raise    [Error::JobNotFound]  Raised when `job` could not be found.
    def job_done?( job, fail_if_not_found = true )
        synchronize do
            fail_if_job_not_found job if fail_if_not_found
            return false if !@pending_jobs.include?( job.id )
            @pending_jobs[job.id] == 0
        end
    end

    # @param    [Job::Result]  result
    def handle_job_result( result )
        return if job_done? result.job
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
        @shutdown = true

        # Kill the browsers.
        (@browsers[:idle] | @browsers[:busy]).each(&:shutdown)

        # Clear the temp files used to hold the jobs.
        @jobs.clear

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

    def update_skip_lookup_for( id, lookups )
        synchronize {
            skip_lookup_for( id ).collection.merge lookups
        }
    end

    def skip_lookup_for( id )
        @skip[id] ||= Support::LookUp::HashSet.new( hasher: :persistent_hash )
    end

    def move_browser( browser, from_state, to_state, job = nil )
        synchronize do
            @browsers[to_state] << @browsers[from_state].delete( browser )

            next if !job
            @pending_jobs[job.id] -= 1
            job_done( job ) if @pending_jobs[job.id] <= 0
        end
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

    def initialize_browsers
        print_status 'Initializing browsers...'

        @browsers = {
            idle: [],
            busy: []
        }

        @javascript_token = Utilities.generate_token

        pool_size.times do
            @browsers[:idle] << Peer.new(
                javascript_token: @javascript_token,
                master:           self
            )
        end

        print_status "Initialization complete, #{pool_size} browsers are in the pool."
    end

end
end
