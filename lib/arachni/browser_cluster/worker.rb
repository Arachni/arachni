=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end


module Arachni

require Options.paths.lib + 'browser'

class BrowserCluster

# Overrides some {Arachni::Browser} methods to make multiple browsers play well
# with each other when they're part of a {BrowserCluster}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Worker < Arachni::Browser
    personalize_output

    # @return    [BrowserCluster]
    attr_reader   :master

    # @return    [Job]
    #   Currently assigned job.
    attr_reader   :job

    # @return   [Integer]
    attr_accessor :job_timeout

    # @return    [Integer]
    attr_accessor :max_time_to_live

    # @return    [Integer]
    #   Remaining time-to-live measured in jobs.
    attr_reader   :time_to_live

    def initialize( options = {} )
        @master           = options.delete( :master )

        @max_time_to_live = options.delete( :max_time_to_live ) ||
            Options.browser_cluster.worker_time_to_live
        @time_to_live     = @max_time_to_live

        @job_timeout      = options.delete( :job_timeout ) ||
            Options.browser_cluster.job_timeout

        # Don't store pages if there's a master, we'll be sending them to him
        # as soon as they're logged.
        super options.merge( store_pages: false )

        @done_signal = Queue.new

        start_capture

        return if !@master
        start
    end

    # @param    [BrowserCluster::Job]  job
    #
    # @return   [Array<Page>]
    #   Pages which resulted from firing events, clicking JavaScript links
    #   and capturing AJAX requests.
    #
    # @see Arachni::Browser#trigger_events
    def run_job( job )
        @job = job
        print_debug "Started: #{@job}"

        # PhantomJS may have crashed (it happens sometimes) so make sure that
        # we've got a live one before running the job.
        # If we can't respawn, then bail out.
        return if browser_respawn_if_necessary.nil?

        # ap '=' * 250
        # ap '=' * 250
        # pre = $WATIR_REQ_COUNT

        time = Time.now
        begin
            with_timeout @job_timeout do
                exception_jail false do
                    begin
                        @job.configure_and_run( self )
                    rescue Selenium::WebDriver::Error::WebDriverError,
                        Watir::Exception::Error => e

                        print_debug "Error while processing job: #{@job}"
                        print_debug
                        print_debug_exception e

                        browser_respawn
                    end
                end
            end

            job.time = Time.now - time
        rescue TimeoutError => e
            job.timed_out!( Time.now - time )

            print_bad "Job timed-out after #{@job_timeout} seconds: #{@job}"

            # Could have left us with a broken browser.
            browser_respawn
        end

        # ap $WATIR_REQ_COUNT - pre

        decrease_time_to_live
        browser_respawn_if_necessary

        print_debug "Finished: #{@job}"

        true
    rescue Selenium::WebDriver::Error::WebDriverError
        browser_respawn
        nil
    ensure
        @javascript.taint = nil

        clear_buffers

        # The jobs may have configured callbacks to capture pages etc.,
        # remove them.
        clear_observers

        @job = nil
    end

    # Direct the distribution to the master and let it take it from there.
    #
    # @see Jobs::EventTrigger
    # @see BrowserCluster#queue
    def distribute_event( page, element, event )
        master.queue @job.forward_as(
            @job.class::EventTrigger,
            resource: page,
            element:  element,
            event:    event
        )
        true
    # Job may have been marked as done or the cluster may have been shut down.
    rescue BrowserCluster::Job::Error::AlreadyDone,
        BrowserCluster::Error::AlreadyShutdown
        false
    end

    # @note If there is a running job it will wait for it to finish.
    #
    # Shuts down the worker.
    def shutdown( wait = true )
        return if @shutdown
        @shutdown = true

        # Keep checking to see if any of the 'done' criteria are true.
        kill_check = Thread.new do
            sleep 0.1 while alive? && wait && @job
            @done_signal << nil
        end

        # If we've got a job running wait for it to finish before closing the
        # browser otherwise we'll get Selenium errors and zombie processes.
        @done_signal.pop
        kill_check.join
        @consumer.kill if @consumer

        super()
    end

    def inspect
        s = "#<#{self.class} "
        s << "pid=#{@lifeline_pid} "
        s << "job=#{@job.inspect} "
        s << "last-url=#{@last_url.inspect} "
        s << "transitions=#{@transitions.size}"
        s << '>'
    end

    def self.name
        "BrowserCluster Worker##{object_id}"
    end

    private

    # @return   [Support::LookUp::HashSet]
    #   States that have been visited and should be skipped, for the given
    #   {#job}.
    #
    # @see #skip_state
    # @see #skip_state?
    def skip_states
        master.skip_states job.id
    end

    def skip_state?( state )
        master.skip_state? job.id, state
    end

    def skip_state( state )
        master.skip_state job.id, state
    end

    def update_skip_states( states )
        master.update_skip_states job.id, states
    end

    def start
        @consumer ||= Thread.new do
            while !@shutdown
                exception_jail false do
                    j = master.pop
                    exception_jail( false ) { run_job j }
                    master.decrease_pending_job j
                end
            end
            @done_signal << nil
        end
    end

    def browser_respawn_if_necessary
        return false if !time_to_die? && alive?
        browser_respawn
    end

    def browser_respawn
        @time_to_live = @max_time_to_live

        begin
            # If PhantomJS is already dead this will block for quite some time so
            # beware.
            @watir.close if @watir && alive?
        rescue Selenium::WebDriver::Error::WebDriverError,
            Watir::Exception::Error
        end

        kill_process

        # Browser may fail to respawn but there's nothing we can do about
        # that, just leave it dead and try again at the next job.
        begin
            @watir = ::Watir::Browser.new( selenium )
            true
        rescue Selenium::WebDriver::Error::WebDriverError,
            Browser::Error::Spawn => e
            print_error 'Could not respawn the browser, will try again at the ' <<
                            "next job. (#{e})"
            print_error 'Please try increasing the maximum open files limit of your OS.'
            nil
        end
    end

    def time_to_die?
        @time_to_live <= 0
    end

    def decrease_time_to_live
        @time_to_live -= 1
    end

    def save_response( response )
        super( response )
        master.push_to_sitemap( response.url, response.code )
        response
    end

end
end
end
