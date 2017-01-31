=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'framework/rpc'

module Arachni
class State

# State information for {Arachni::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Framework

    # {Framework} error namespace.
    #
    # All {Framework} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < State::Error
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class StateNotSuspendable < Error
        end

        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class StateNotAbortable < Error
        end

        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class InvalidStatusMessage < Error
        end
    end

    # @return     [RPC]
    attr_accessor :rpc

    # @return     [Support::LookUp::HashSet]
    attr_reader   :page_queue_filter

    # @return     [Support::LookUp::HashSet]
    attr_reader   :url_queue_filter

    # @return     [Support::LookUp::HashSet]
    attr_reader   :element_pre_check_filter

    # @return     [Set]
    attr_reader   :browser_skip_states

    # @return     [Symbol]
    attr_accessor :status

    # @return     [Bool]
    attr_accessor :running

    # @return     [Integer]
    attr_accessor :audited_page_count

    # @return     [Array]
    attr_reader   :pause_signals

    # @return     [Array<String>]
    attr_reader    :status_messages

    def initialize
        @rpc = RPC.new
        @audited_page_count = 0

        @browser_skip_states = Support::LookUp::HashSet.new( hasher: :persistent_hash )

        @page_queue_filter = Support::LookUp::HashSet.new( hasher: :persistent_hash )
        @url_queue_filter  = Support::LookUp::HashSet.new( hasher: :persistent_hash )

        @element_pre_check_filter = Support::LookUp::HashSet.new( hasher: :coverage_hash )

        @running = false
        @pre_pause_status = nil

        @pause_signals    = Set.new
        @paused_signal    = Queue.new
        @suspended_signal = Queue.new
        @aborted_signal   = Queue.new

        @status_messages = []
    end

    def statistics
        {
            rpc:                @rpc.statistics,
            audited_page_count: @audited_page_count,
            browser_states:     @browser_skip_states.size
        }
    end

    # @return   [Hash{Symbol=>String}]
    #   All possible {#status_messages} by type.
    def available_status_messages
        {
            suspending:                       'Will suspend as soon as the current page is audited.',
            waiting_for_browser_cluster_jobs: 'Waiting for %i browser cluster jobs to finish.',
            suspending_plugins:               'Suspending plugins.',
            saving_snapshot:                  'Saving snapshot at: %s',
            snapshot_location:                'Snapshot location: %s',
            browser_cluster_startup:          'Initialising the browser cluster.',
            browser_cluster_shutdown:         'Shutting down the browser cluster.',
            clearing_queues:                  'Clearing the audit queues.',
            waiting_for_plugins:              'Waiting for the plugins to finish.',
            aborting:                         'Aborting the scan.'
        }
    end

    # Sets a message as {#status_messages}.
    #
    # @param    (see #add_status_message)
    # @return   (see #add_status_message)
    def set_status_message( *args )
        clear_status_messages
        add_status_message( *args )
    end

    # Pushes a message to {#status_messages}.
    #
    # @param    [String, Symbol]    message
    #   Status message. If `Symbol`, it will be grabbed from
    #   {#available_status_messages}.
    # @param    [String, Numeric]    sprintf
    #   `sprintf` arguments.
    def add_status_message( message, *sprintf )
        if message.is_a? Symbol
            if !available_status_messages.include?( message )
                fail Error::InvalidStatusMessage,
                     "Could not find status message for: '#{message}'"
            end

            message = available_status_messages[message] % sprintf
        end

        @status_messages << message.to_s
    end

    # Clears {#status_messages}.
    def clear_status_messages
        @status_messages.clear
    end

    # @param    [Page]  page
    #
    # @return    [Bool]
    #   `true` if the `page` has already been seen (based on the
    #   {#page_queue_filter}), `false` otherwise.
    #
    # @see #page_seen
    def page_seen?( page )
        @page_queue_filter.include? page
    end

    # @param    [Page]  page
    #   Page to mark as seen.
    #
    # @see #page_seen?
    def page_seen( page )
        @page_queue_filter << page
    end

    # @param    [String]  url
    #
    # @return    [Bool]
    #   `true` if the `url` has already been seen (based on the
    #   {#url_queue_filter}), `false` otherwise.
    #
    # @see #url_seen
    def url_seen?( url )
        @url_queue_filter.include? url
    end

    # @param    [Page]  url
    #   URL to mark as seen.
    #
    # @see #url_seen?
    def url_seen( url )
        @url_queue_filter << url
    end

    # @param    [Support::LookUp::HashSet]  states
    def update_browser_skip_states( states )
        @browser_skip_states.merge states
    end

    # @param    [#coverage_hash]  e
    #
    # @return    [Bool]
    #   `true` if the element has already been seen (based on the
    #   {#element_pre_check_filter}), `false` otherwise.
    #
    # @see #element_checked
    def element_checked?( e )
        @element_pre_check_filter.include? e
    end

    # @param    [Page]  e
    #   Element to mark as seen.
    #
    # @see #element_checked?
    def element_checked( e )
        @element_pre_check_filter << e
    end

    def running?
        !!@running
    end

    # @param    [Bool]  block
    #   `true` if the method should block until an abortion has completed,
    #   `false` otherwise.
    #
    # @return   [Bool]
    #   `true` if the abort request was successful, `false` if the system is
    #   already {#suspended?} or is {#suspending?}.
    #
    # @raise    [StateNotAbortable]
    #   When not {#running?}.
    def abort( block = true )
        return false if aborting? || aborted?

        if !running?
            fail Error::StateNotAbortable, 'Cannot abort an idle state.'
        end

        set_status_message :aborting
        @status = :aborting
        @abort = true

        @aborted_signal.pop if block
        true
    end

    # @return   [Bool]
    #   `true` if a {#abort} signal is in place , `false` otherwise.
    def abort?
        !!@abort
    end

    # Signals a completed abort operation.
    def aborted
        @abort = false
        @status = :aborted
        @aborted_signal << true
        nil
    end

    # @return   [Bool]
    #   `true` if the system has been aborted, `false` otherwise.
    def aborted?
        @status == :aborted
    end

    # @return   [Bool]
    #   `true` if the system is being aborted, `false` otherwise.
    def aborting?
        @status == :aborting
    end

    # @return   [Bool]
    #   `true` if the system has completed successfully, `false` otherwise.
    def done?
        @status == :done
    end

    # @param    [Bool]  block
    #   `true` if the method should block until a suspend has completed,
    #   `false` otherwise.
    #
    # @return   [Bool]
    #   `true` if the suspend request was successful, `false` if the system is
    #   already {#suspended?} or is {#suspending?}.
    #
    # @raise    [StateNotSuspendable]
    #   When {#paused?} or {#pausing?}.
    def suspend( block = true )
        return false if suspending? || suspended?

        if paused? || pausing?
            fail Error::StateNotSuspendable, 'Cannot suspend a paused state.'
        end

        if !running?
            fail Error::StateNotSuspendable, 'Cannot suspend an idle state.'
        end

        set_status_message :suspending
        @status = :suspending
        @suspend = true

        @suspended_signal.pop if block
        true
    end

    # @return   [Bool]
    #   `true` if an {#abort} signal is in place , `false` otherwise.
    def suspend?
        !!@suspend
    end

    # Signals a completed suspension.
    def suspended
        @suspend = false
        @status = :suspended
        @suspended_signal << true
        nil
    end

    # @return   [Bool]
    #   `true` if the system has been suspended, `false` otherwise.
    def suspended?
        @status == :suspended
    end

    # @return   [Bool]
    #   `true` if the system is being suspended, `false` otherwise.
    def suspending?
        @status == :suspending
    end

    # @return   [Bool]
    #   `true` if the system is scanning, `false` otherwise.
    def scanning?
        @status == :scanning
    end

    # @param    [Object]    caller
    #   Identification for the caller which issued the pause signal.
    # @param    [Bool]  block
    #   `true` if the method should block until the pause has completed,
    #   `false` otherwise.
    #
    # @return   [TrueClass]
    #   Pauses the framework on a best effort basis, might take a while to take
    #   effect.
    def pause( caller, block = true )
        @pre_pause_status ||= @status if !paused? && !pausing?

        if !paused?
            @status = :pausing
        end

        @pause_signals << caller

        paused if !running?

        @paused_signal.pop if block && !paused?
        true
    end

    # Signals that the system has been paused..
    def paused
        clear_status_messages
        @status = :paused
        @paused_signal << nil
    end

    # @return   [Bool]
    #   `true` if the framework is paused.
    def paused?
        @status == :paused
    end

    # @return   [Bool]
    #   `true` if the system is being paused, `false` otherwise.
    def pausing?
        @status == :pausing
    end

    # @return   [Bool]
    #   `true` if the framework should pause, `false` otherwise.
    def pause?
        @pause_signals.any?
    end

    # Resumes a paused system
    #
    # @param    [Object]    caller
    #   Identification for the caller whose {#pause} signal to remove. The
    #   system is resumed once there are no more {#pause} signals left.
    #
    # @return   [Bool]
    #   `true` if the system is resumed, `false` if there are more {#pause}
    #   signals pending.
    def resume( caller )
        @pause_signals.delete( caller )

        if @pause_signals.empty?
            @status = @pre_pause_status
            @pre_pause_status = nil
            return true
        end

        false
    end

    def force_resume
        @pause_signals.to_a.each do |ref|
            resume ref
        end
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        rpc.dump( "#{directory}/rpc/" )

        %w(element_pre_check_filter page_queue_filter url_queue_filter
            browser_skip_states audited_page_count).each do |attribute|
            IO.binwrite( "#{directory}/#{attribute}", Marshal.dump( send(attribute) ) )
        end
    end

    def self.load( directory )
        framework = new

        framework.rpc = RPC.load( "#{directory}/rpc/" )

        %w(element_pre_check_filter page_queue_filter url_queue_filter
            browser_skip_states).each do |attribute|
            path = "#{directory}/#{attribute}"
            next if !File.exist?( path )

            framework.send(attribute).merge Marshal.load( IO.binread( path ) )
        end

        framework.audited_page_count = Marshal.load( IO.binread( "#{directory}/audited_page_count" ) )
        framework
    end

    def clear
        rpc.clear

        @element_pre_check_filter.clear

        @page_queue_filter.clear
        @url_queue_filter.clear

        @pause_signals.clear
        @paused_signal.clear
        @suspended_signal.clear

        @running = false
        @pre_pause_status = nil

        @browser_skip_states.clear
        @audited_page_count = 0
    end

end

end
end
