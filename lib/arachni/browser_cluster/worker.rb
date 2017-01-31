=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

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

    # How many times to retry timed-out jobs.
    TRIES = 6

    # @return    [BrowserCluster]
    attr_reader   :master

    # @return    [Job]
    #   Currently assigned job.
    attr_reader   :job

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

        @done_signal = Queue.new

        # Don't store pages if there's a master, we'll be sending them to him
        # as soon as they're logged.
        super options.merge( store_pages: false )

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

        tries = 0
        begin

            time = Time.now

            @job.configure_and_run( self )

            @job.time = Time.now - time

        rescue Selenium::WebDriver::Error::WebDriverError,
            Watir::Exception::Error => e

            print_debug "WebDriver error while processing job: #{@job}"
            print_debug_exception e

            browser_respawn

        # This can be thrown by a Selenium call somewhere down the line,
        # catch it here and retry the entire job.
        rescue Timeout::Error => e

            tries += 1
            if !@shutdown && tries <= TRIES
                print_info "Retrying (#{tries}/#{TRIES}) due to time out: #{@job}"
                print_debug_exception e

                browser_respawn
                reset

                retry
            end

            @job.timed_out!( Time.now - time )

            print_bad "Job timed-out #{TRIES} times: #{@job}"
            master.increment_time_out_count

            # Could have left us with a broken browser.
            browser_respawn
        end

        decrease_time_to_live
        browser_respawn_if_necessary

    # Something went horribly wrong, cleanup.
    rescue => e
        print_error "Error while processing job: #{@job}"
        print_exception e

        browser_respawn
    ensure
        print_debug "Finished: #{@job}"
        @job = nil

        reset
        master.job_done job
    end

    # Direct the distribution to the master and let it take it from there.
    #
    # @see Jobs::EventTrigger
    # @see BrowserCluster#queue
    def distribute_event( resource, element, event )
        master.queue(
            @job.forward_as(
                @job.class::EventTrigger,
                resource: resource,
                element:  element,
                event:    event
            ),
            master.callback_for( @job )
        )
        true
    # Job may have been marked as done or the cluster may have been shut down.
    rescue BrowserCluster::Job::Error::AlreadyDone,
        BrowserCluster::Error::AlreadyShutdown
        false
    end

    alias :browser_shutdown :shutdown
    # @note If there is a running job it will wait for it to finish.
    #
    # Shuts down the worker.
    def shutdown( wait = true )
        return if @shutdown
        @shutdown = true

        print_debug "Shutting down (wait: #{wait}) ..."

        # Keep checking to see if any of the 'done' criteria are true.
        kill_check = Thread.new do
            while alive? && wait && @job
                print_debug_level_2 "Waiting for job to complete: #{job}"
                sleep 0.1
            end

            print_debug_level_2 'Signaling done.'
            @done_signal << nil
        end

        print_debug_level_2 'Waiting for done signal...'
        # If we've got a job running wait for it to finish before closing the
        # browser otherwise we'll get Selenium errors and zombie processes.
        @done_signal.pop
        print_debug_level_2 '...done.'

        print_debug_level_2 'Waiting for kill check...'
        kill_check.join
        print_debug_level_2 '...done.'

        if @consumer
            print_debug_level_2 'Killing consumer thread...'
            @consumer.kill
            print_debug_level_2 '...done.'
        end

        print_debug_level_2 'Calling parent shutdown...'
        browser_shutdown
        print_debug_level_2 '...done.'

        print_debug '...shutdown complete.'
    end

    def inspect
        s = "#<#{self.class} "
        s << "pid=#{@lifeline_pid} "
        s << "job=#{@job.inspect} "
        s << "last-url=#{@last_url.inspect} "
        s << "transitions=#{@transitions.size}"
        s << '>'
    end

    private

    def reset
        @javascript.taint = nil

        clear_buffers

        # The jobs may have configured callbacks to capture pages etc.,
        # remove them.
        clear_observers
    end

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
                run_job master.pop
            end

            print_debug 'Got shutdown signal...'
            @done_signal << nil
            print_debug '...and acknowledged it.'
        end
    end

    def browser_respawn_if_necessary
        return false if !time_to_die? && alive?
        browser_respawn
    end

    def browser_respawn
        print_debug "Re-spawning browser (TTD?: #{time_to_die?} - alive?: #{alive?}) ..."
        @time_to_live = @max_time_to_live

        browser_shutdown

        # Browser may fail to respawn but there's nothing we can do about that,
        # just leave it dead and try again at the next job.
        r = begin

            start_webdriver

            true
        rescue Selenium::WebDriver::Error::WebDriverError,
            Browser::Error::Spawn => e

            print_error 'Could not respawn the browser, will try again at' <<
                            " the next job. (#{e})"
            print_error 'Please try increasing the maximum open files limit' <<
                            ' of your OS.'
            nil
        end

        print_debug "...re-spawned browser: #{r}"

        r
    end

    def time_to_die?
        @time_to_live <= 0
    end

    def decrease_time_to_live
        @time_to_live -= 1
    end

end
end
end
