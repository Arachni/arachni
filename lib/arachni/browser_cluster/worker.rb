=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end


module Arachni

lib = Options.paths.lib
require lib + 'browser'
require lib + 'rpc/server/base'
require lib + 'processes'
require lib + 'framework'

class BrowserCluster

# Overrides some {Arachni::Browser} methods to make multiple browsers play well
# with each other when they're part of a {BrowserCluster}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Worker < Arachni::Browser

    # Maximum allowed time for jobs in seconds. One hour is pretty close to
    # not having a timeout at all but it's good to at least have the option
    # for future use.
    JOB_TIMEOUT = 3600

    # @return    [BrowserCluster]
    attr_reader :master

    # @return [Job] Currently assigned job.
    attr_reader :job

    def initialize( options )
        javascript_token = options.delete( :javascript_token )
        @master          = options.delete( :master )

        # Don't store pages if there's a master, we'll be sending them to him
        # as soon as they're logged.
        super options.merge( store_pages: false )

        @javascript.token = javascript_token

        @stop_signal = Queue.new
        @done_signal = Queue.new

        start_capture
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

        begin
            Timeout.timeout( JOB_TIMEOUT ) do
                begin
                    @job.configure_and_run( self )
                rescue => e
                    print_error e
                    print_error_backtrace e
                end
            end
        rescue TimeoutError
            print_error "Job timed-out after #{JOB_TIMEOUT} seconds: #{job}"
        end

        @responses.clear

        # The jobs may have configured callbacks to capture pages etc.,
        # remove them.
        @on_new_page_blocks.clear
        @on_new_page_with_sink_blocks.clear
        @on_response_blocks.clear

        # Close open windows to free system resources and have a clean
        # slate for the next job.
        #
        # WARNING: This somehow leads to freezes, after a few jobs when
        # triggering events, put it on the back burner and uncomment when I
        # figure it out.
        #close_windows

        @job = nil

        true
    end

    # @return   [Support::LookUp::HashSet]
    #   States that have been visited and should be skipped, for the given
    #   {#job}.
    #
    # @see #skip_state
    # @see #skip_state?
    def skip_states
        master.skip_states_for( job.id )
    end

    # We change the default scheduling to distribute elements and events
    # to all available browsers ASAP, instead of building a list and then
    # consuming it, since we're don't have to worry about messing up our
    # page's state in this setup.
    #
    # @see Browser#trigger_events
    def trigger_events
        root_page = to_page

        each_element_with_events do |info|
            info[:events].each do |name, _|
                distribute_event( root_page, info[:tag], name.to_sym )
            end
        end

        true
    end

    # Direct the distribution to the master and let it take it from there.
    #
    # @see Jobs::EventTrigger
    # @see BrowserCluster#queue
    def distribute_event( page, tag, event )
        master.queue @job.forward_as(
            @job.class::EventTrigger,
            {
                resource: page,
                tag:      tag,
                event:    event
            }
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
    def shutdown
        return if @shutdown
        @shutdown = true

        # If we've got a job running wait for it to finish before closing
        # the browser otherwise we'll get Selenium errors and zombie processes.
        if @job
            @stop_signal << nil
            @done_signal.pop
        end

        super
    end

    private

    def start
        @consumer ||= Thread.new do
            while @stop_signal.empty?
                job = master.pop
                run_job job
                master.decrease_pending_job( job )
            end
            @done_signal << nil
        end
    end

    def save_response( response )
        super( response )
        master.push_to_sitemap( response.url, response.code )
        response
    end

end
end
end
