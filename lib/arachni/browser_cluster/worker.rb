=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end


module Arachni

require Options.paths.lib + 'browser'

class BrowserCluster

# Overrides some {Arachni::Browser} methods to make multiple browsers play well
# with each other when they're part of a {BrowserCluster}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Worker < Arachni::Browser
    personalize_output

    # @return   [Integer]
    #   We can't just close all windows because PhantomJS for some reason
    #   freezes after we do it a lot of times and we can't just leave open
    #   windows accumulate, so we've got to take more drastic measures and kill
    #   it when the amount of open windows reaches or exceeds this setting.
    RESPAWN_WHEN_WINDOW_COUNT_REACHES = 5

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
        javascript_token  = options.delete( :javascript_token )
        @master           = options.delete( :master )

        @max_time_to_live = options.delete( :max_time_to_live ) ||
            Options.browser_cluster.worker_time_to_live
        @time_to_live     = @max_time_to_live

        @job_timeout      = options.delete( :job_timeout ) ||
            Options.browser_cluster.job_timeout

        # Don't store pages if there's a master, we'll be sending them to him
        # as soon as they're logged.
        super options.merge( store_pages: false )

        @javascript.token = javascript_token

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

        # PhantomJS may have crashed (it happens sometimes) so make sure that
        # we've got a live one before running the job.
        browser_respawn_if_necessary

        begin
            with_timeout @job_timeout do
                exception_jail false do
                    @job.configure_and_run( self )
                end
            end
        rescue TimeoutError => e
            print_debug "Job timed-out after #{@job_timeout} seconds: #{job}"

            # Could have left us with a broken browser.
            browser_respawn
        end

        @javascript.taint = nil

        @preloads.clear
        @cache.clear
        @captured_pages.clear
        @page_snapshots.clear
        @page_snapshots_with_sinks.clear

        # The jobs may have configured callbacks to capture pages etc.,
        # remove them.
        clear_observers

        begin
            watir.cookies.clear
        # Working window was closed by JS (probably), start from scratch.
        rescue Selenium::WebDriver::Error::NoSuchWindowError
            browser_respawn
        end

        decrease_time_to_live
        browser_respawn_if_necessary

        true
    ensure
        @job = nil
    end

    # We change the default scheduling to distribute elements and events to all
    # available browsers ASAP, instead of building a list and then consuming it,
    # since we're don't have to worry about messing up our page's state in this
    # setup.
    #
    # @see Browser#trigger_events
    def trigger_events
        root_page = to_page

        each_element_with_events do |element, events|
            events.each do |name, _|
                distribute_event( root_page, element, name.to_sym )
            end
        end

        true
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
            sleep 0.1 while browser_alive? && wait && @job
            @done_signal << nil
        end

        # If we've got a job running wait for it to finish before closing the
        # browser otherwise we'll get Selenium errors and zombie processes.
        @done_signal.pop
        kill_check.join
        @consumer.kill if @consumer

        super()
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

    def browser_alive?
        @process.alive?
    rescue Errno::ECHILD
        false
    end

    def browser_respawn_if_necessary
        return if !time_to_die? && browser_alive? &&
            watir.windows.size < RESPAWN_WHEN_WINDOW_COUNT_REACHES

        browser_respawn
    end

    def browser_respawn
        @time_to_live = @max_time_to_live

        @window_responses.clear

        # If PhantomJS is already dead this will block for quite some time so
        # beware.
        @watir.close if browser_alive?

        kill_process

        @watir    = nil
        @selenium = nil

        @watir = ::Watir::Browser.new( selenium )

        ensure_open_window
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
