=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Framework
module Parts

# Provides access to {Arachni::State::Framework} and helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module State

    def self.included( base )
        base.extend ClassMethods
    end

    module ClassMethods

        # @param   [String]    afs
        #   Path to an `.afs.` (Arachni Framework Snapshot) file created by
        #   {#suspend}.
        #
        # @return   [Framework]
        #   Restored instance.
        def restore( afs, &block )
            framework = new
            framework.restore( afs )

            if block_given?
                begin
                    block.call framework
                ensure
                    framework.clean_up
                    framework.reset
                end
            end

            framework
        end

        # @note You should first reset {Arachni::Options}.
        #
        # Resets everything and allows the framework environment to be re-used.
        def reset
            Arachni::State.clear
            Arachni::Data.clear

            Arachni::Platform::Manager.reset
            Arachni::Check::Auditor.reset
            ElementFilter.reset
            Element::Capabilities::Auditable.reset
            Element::Capabilities::Analyzable.reset
            Arachni::Check::Manager.reset
            Arachni::Plugin::Manager.reset
            Arachni::Reporter::Manager.reset
            HTTP::Client.reset
        end
    end

    def initialize
        super

        Element::Capabilities::Auditable.skip_like do |element|
            if pause?
                print_debug "Blocking on element audit: #{element.audit_id}"
            end

            wait_if_paused
        end

        state.status = :ready
    end

    # @return   [String]
    #   Provisioned {#suspend} dump file for this instance.
    def snapshot_path
        return @state_archive if @state_archive

        default_filename =
            "#{URI(options.url).host} #{Time.now.to_s.gsub( ':', '_' )} " <<
                "#{generate_token}.afs"

        location = options.snapshot.save_path

        if !location
            location = default_filename
        elsif File.directory? location
            location += "/#{default_filename}"
        end

        @state_archive ||= File.expand_path( location )
    end

    # Cleans up the framework; should be called after running the audit or
    # after canceling a running scan.
    #
    # It stops the clock and waits for the plugins to finish up.
    def clean_up( shutdown_browsers = true )
        return if @cleaned_up
        @cleaned_up = true

        state.force_resume

        state.status = :cleanup

        if shutdown_browsers
            state.set_status_message :browser_cluster_shutdown
            shutdown_browser_cluster
        end

        state.set_status_message :clearing_queues
        page_queue.clear
        url_queue.clear

        @finish_datetime  = Time.now
        @start_datetime ||= Time.now

        # Make sure this is disabled or it'll break reporter output.
        disable_only_positives

        state.running = false

        state.set_status_message :waiting_for_plugins
        @plugins.block

        # Plugins may need the session right till the very end so save it for last.
        @session.clean_up
        @session = nil

        true
    end

    # @private
    def reset_trainer
        @trainer = Trainer.new( self )
    end

    # @note Prefer this from {.reset} if you already have an instance.
    # @note You should first reset {Arachni::Options}.
    #
    # Resets everything and allows the framework to be re-used.
    def reset
        @cleaned_up  = false
        @browser_job = nil

        @failures.clear
        @retries.clear

        # This needs to happen before resetting the other components so they
        # will be able to put in their hooks.
        self.class.reset

        clear_observers
        reset_trainer
        reset_session

        @checks.clear
        @reporters.clear
        @plugins.clear
    end

    # @return   [State::Framework]
    def state
        Arachni::State.framework
    end

    # @param   [String]    afs
    #   Path to an `.afs.` (Arachni Framework Snapshot) file created by {#suspend}.
    #
    # @return   [Framework]
    #   Restored instance.
    def restore( afs )
        Snapshot.load afs

        browser_job_update_skip_states state.browser_skip_states

        checks.load  Options.checks
        plugins.load Options.plugins.keys

        nil
    end

    # @return   [Array<String>]
    #   Messages providing more information about the current {#status} of
    #   the framework.
    def status_messages
        state.status_messages
    end

    # @return   [Symbol]
    #   Status of the instance, possible values are (in order):
    #
    #   * `:ready` -- {#initialize Initialised} and waiting for instructions.
    #   * `:preparing` -- Getting ready to start (i.e. initializing plugins etc.).
    #   * `:scanning` -- The instance is currently {#run auditing} the webapp.
    #   * `:pausing` -- The instance is being {#pause paused} (if applicable).
    #   * `:paused` -- The instance has been {#pause paused} (if applicable).
    #   * `:suspending` -- The instance is being {#suspend suspended} (if applicable).
    #   * `:suspended` -- The instance has being {#suspend suspended} (if applicable).
    #   * `:cleanup` -- The scan has completed and the instance is
    #       {Framework::Parts::State#clean_up cleaning up} after itself (i.e. waiting for
    #       plugins to finish etc.).
    #   * `:aborted` -- The scan has been {Framework::Parts::State#abort}, you can grab the
    #       report and shutdown.
    #   * `:done` -- The scan has completed, you can grab the report and shutdown.
    def status
        state.status
    end

    # @return   [Bool]
    #   `true` if the framework is running, `false` otherwise. This is `true`
    #   even if the scan is {#paused?}.
    def running?
        state.running?
    end

    # @return   [Bool]
    #   `true` if the system is scanning, `false` otherwise.
    def scanning?
        state.scanning?
    end

    # @return   [Bool]
    #   `true` if the framework is paused, `false` otherwise.
    def paused?
        state.paused?
    end

    # @return   [Bool]
    #   `true` if the framework has been instructed to pause (i.e. is in the
    #   process of being paused or has been paused), `false` otherwise.
    def pause?
        state.pause?
    end

    # @return   [Bool]
    #   `true` if the framework is in the process of pausing, `false` otherwise.
    def pausing?
        state.pausing?
    end

    # @return   (see Arachni::State::Framework#done?)
    def done?
        state.done?
    end

    # @note Each call from a unique caller is counted as a pause request
    #   and in order for the system to resume **all** pause callers need to
    #   {#resume} it.
    #
    # Pauses the framework on a best effort basis.
    #
    # @param    [Bool]  wait
    #   Wait until the system has been paused.
    #
    # @return   [Integer]
    #   ID identifying this pause request.
    def pause( wait = true )
        id = generate_token.hash
        state.pause id, wait
        id
    end

    # @return   [Bool]
    #   `true` if the framework {#run} has been aborted, `false` otherwise.
    def aborted?
        state.aborted?
    end

    # @return   [Bool]
    #   `true` if the framework has been instructed to abort (i.e. is in the
    #   process of being aborted or has been aborted), `false` otherwise.
    def abort?
        state.abort?
    end

    # @return   [Bool]
    #   `true` if the framework is in the process of aborting, `false` otherwise.
    def aborting?
        state.aborting?
    end

    # Aborts the framework {#run} on a best effort basis.
    #
    # @param    [Bool]  wait
    #   Wait until the system has been aborted.
    def abort( wait = true )
        state.abort wait
    end

    # @note Each call from a unique caller is counted as a pause request
    #   and in order for the system to resume **all** pause callers need to
    #   {#resume} it.
    #
    # Removes a {#pause} request for the current caller.
    #
    # @param    [Integer]   id
    #   ID of the {#pause} request.
    def resume( id )
        state.resume id
    end

    # Writes a {Snapshot.dump} to disk and aborts the scan.
    #
    # @param   [Bool]  wait
    #   Wait for the system to write it state to disk.
    #
    # @return   [String,nil]
    #   Path to the state file `wait` is `true`, `nil` otherwise.
    def suspend( wait = true )
        state.suspend( wait )
        return snapshot_path if wait
        nil
    end

    # @return   [Bool]
    #   `true` if the system is in the process of being suspended, `false`
    #   otherwise.
    def suspend?
        state.suspend?
    end

    # @return   [Bool]
    #   `true` if the system has been suspended, `false` otherwise.
    def suspended?
        state.suspended?
    end

    private

    # @note Must be called before calling any audit methods.
    #
    # Prepares the framework for the audit.
    #
    # * Sets the status to `:preparing`.
    # * Starts the clock.
    # * Runs the plugins.
    def prepare
        state.status  = :preparing
        state.running = true
        @start_datetime = Time.now

        Snapshot.restored? ? @plugins.restore : @plugins.run
    end

    def reset_session
        @session.clean_up if @session
        @session = Session.new
    end

    # Small but (sometimes) important optimization:
    #
    # Keep track of page elements which have already been passed to checks,
    # in order to filter them out and hopefully even avoid running checks
    # against pages with no new elements.
    #
    # It's not like there were going to be redundant audits anyways, because
    # each layer of the audit performs its own redundancy checks, but those
    # redundancy checks can introduce significant latencies when dealing
    # with pages with lots of elements.
    def pre_audit_element_filter( page )
        unique_elements  = {}
        page.elements.each do |e|
            next if !Options.audit.element?( e.type )
            next if e.is_a?( Cookie ) || e.is_a?( Header )

            new_element               = false
            unique_elements[e.type] ||= []

            if !state.element_checked?( e )
                state.element_checked e
                new_element = true
            end

            if page.dom.depth > 0 && e.respond_to?( :dom ) && e.dom
                if !state.element_checked?( e.dom )
                    state.element_checked e.dom
                    new_element = true
                end
            end

            next if !new_element

            unique_elements[e.type] << e
        end

        # Remove redundant elements from the page cache, if there are thousands
        # of them then just skipping them during the audit will introduce latency.
        unique_elements.each do |type, elements|
            page.send( "#{type}s=", elements )
        end

        page
    end

    def handle_signals
        wait_if_paused
        abort_if_signaled
        suspend_if_signaled
    end

    def wait_if_paused
        state.paused if pause?
        sleep 0.2 while pause? && !abort?
    end

    def abort_if_signaled
        return if !abort?
        clean_up
        state.aborted
    end

    def suspend_if_signaled
        return if !suspend?
        suspend_to_disk
    end

    def suspend_to_disk
        while wait_for_browser_cluster?
            last_pending_jobs ||= 0
            pending_jobs = browser_cluster.pending_job_counter

            if pending_jobs != last_pending_jobs
                state.set_status_message :waiting_for_browser_cluster_jobs, pending_jobs
                print_info "Suspending: #{status_messages.first}"
            end

            last_pending_jobs = pending_jobs
            sleep 0.1
        end

        # Make sure the component options are up to date with what's actually
        # happening.
        options.checks  = checks.loaded
        options.plugins = plugins.loaded.
            inject({}) { |h, name| h[name.to_s] = Options.plugins[name.to_s] || {}; h }

        if browser_cluster_job_skip_states
            state.browser_skip_states.merge browser_cluster_job_skip_states
        end

        state.set_status_message :suspending_plugins
        @plugins.suspend

        state.set_status_message :saving_snapshot, snapshot_path
        Snapshot.dump( snapshot_path )
        state.clear_status_messages

        clean_up

        state.set_status_message :snapshot_location, snapshot_path
        print_info status_messages.first
        state.suspended
    end

end

end
end
end
