=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end


module Arachni
class Page
class DOM

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Transition

    # {Transition} error namespace.
    #
    # All {Transition} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < DOM::Error

        # Raised when an not-applicable action is performed on a completed
        # transition.
        #
        # @see #start
        # @see #complete
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class Completed < Error
        end

        # Raised when an not-applicable action is performed on a running
        # transition.
        #
        # @see #start
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class Running < Error
        end

        # Raised when an not-applicable action is performed on a not running
        # transition.
        #
        # @see #complete
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class NotRunning < Error
        end

        # Raised when a transition is not {#playable?}.
        #
        # @see #play
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class NotPlayable < Error
        end

        # Raised when an invalid element type is provided.
        #
        # @see #initialize
        # @see #start
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class InvalidElement < Error
        end
    end

    # Non-playable events.
    NON_PLAYABLE = Set.new([:request])

    # Events without a DOM depth.
    ZERO_DEPTH     = Set.new([:request])

    # @return   [Browser::ElementLocator]
    #   HTML element which received the {#event}.
    attr_reader :element

    # @return   [Symbol]
    #   Event triggered on {#element}.
    attr_reader :event

    # @return   [Hash]
    #   Extra options.
    attr_reader :options

    # @return   [Float]
    #   Time it took to trigger the given {#event} on the {#element}.
    attr_accessor :time

    # @note If arguments are provided they will be passed to {#start}.
    #
    # @param    (see #start)
    #
    # @raise    [Error::Completed]
    #   When the transition has been marked as completed.
    # @raise    [Error::Running]
    #   When the transition has already been marked as running.
    # @raise    [Error::InvalidElement]
    #   When an element of invalid type is passed.
    def initialize( *args, &block )
        @options = {}

        return if !args.any?
        start( *args, &block )
    end

    # @param    [String, Symbol]    event
    #   Event associated with this transition -- will be converted to `Symbol`.
    #
    # @return   [Symbol]
    def event=( event )
        @event = event.to_s.to_sym
    end

    # @note Will start the timer for {#time}.
    #
    # @param    [Browser::ElementLocator]  element
    # @param    [Symbol]  event
    # @param    [Hash]  options
    #   Extra options to associate with this transition.
    # @param    [Block] block
    #   If a `block` has been given it will be executed and the transition will
    #   automatically be marked as {#complete finished}.
    #
    # @return   [Transition]    `self`
    #
    # @raise    [Error::Completed]
    #   When the transition has been marked as completed.
    # @raise    [Error::Running]
    #   When the transition has already been marked as running.
    # @raise    [Error::InvalidElement]
    #   When an element of invalid type is passed.
    def start( element, event, options = {}, &block )
        fail Error::Completed, 'Transition has completed.'   if completed?
        fail Error::Running, 'Transition is already running' if running?

        if ![Symbol, String, Browser::ElementLocator].include?( element.class )
            fail Error::InvalidElement
        end

        self.event = event
        @element   = element

        @options = options.my_symbolize_keys(false)
        @clock   = Time.now

        return self if !block_given?

        block.call
        complete
    end

    # @note Will stop the timer for {#time}.
    #
    # Marks the transition as finished.
    #
    # @return   [Transition]
    #   `self`
    #
    # @raise    [Error::Completed]
    #   When the transition has already been marked as completed.
    # @raise    [Error::NotRunning]
    #   When the transition is not running.
    def complete
        fail Error::Completed, 'Transition has completed.'   if completed?
        fail Error::NotRunning, 'Transition is not running.' if !running?

        @time  = Time.now - @clock
        @clock = nil

        self
    end

    # @return   [Integer]
    #   Depth for this transition.
    #
    # @see ZERO_DEPTH
    def depth
        ZERO_DEPTH.include?( event ) ? 0 : 1
    end

    # @param    [Browser]   browser
    #   Browser to use to play the transition.
    #
    # @return   [Transition, nil]
    #   New transition as a result of the play, `nil` if the play wasn't
    #   successful.
    #
    # @raise    [Error::NotPlayable]
    #   When the transition is not {#playable?}.
    def play( browser )
        fail Error::NotPlayable, "Transition is not playable: #{self}" if !playable?

        if element == :page && event == :load
            return browser.goto( options[:url],
                cookies:         options[:cookies],
                take_snapshot:   false
            )
        end

        browser.fire_event element, event, options
    end

    # @return   [Bool]
    #   `true` if the transition is in progress, `false` otherwise.
    #
    # @see #initialize
    # @see #start
    # @see #complete
    def running?
        !!@clock
    end

    # @return   [Bool]
    #   `true` if the transition has completed, `false` otherwise.
    #
    # @see #initialize
    # @see #start
    # @see #complete
    def completed?
        !!@time
    end

    # @return   [Bool]
    #   `true` if the transition is for an event that can be played, `false`
    #   otherwise.
    #
    # @see NON_PLAYABLE
    def playable?
        !NON_PLAYABLE.include?( event )
    end

    # @return   [String]
    def to_s
        "[#{time.to_f}s] '#{event}' on: #{element}"
    end

    def dup
        rpc_clone
    end

    # @return   [Hash]
    def to_hash
        {
            element: element.is_a?( Browser::ElementLocator ) ?
                         element.to_h : element,
            event:   event,
            options: options,
            time:    time
        }
    end
    alias :to_h :to_hash

    # @return   [Hash]
    #   Data representing this instance that are suitable the RPC transmission.
    def to_rpc_data
        h = to_hash.my_stringify_keys(false)
        h['element'] = element.to_rpc_data_or_self
        h
    end

    # @param    [Hash]  data    {#to_rpc_data}
    # @return   [Transition]
    def self.from_rpc_data( data )
        instance = allocate
        data.each do |name, value|

            value = case name
                        when 'event'
                            value.to_sym

                        when 'element'
                            if value.is_a? String
                                data['event'].to_s == 'request' ? value : value.to_sym
                            else
                                Browser::ElementLocator.from_rpc_data( value )
                            end

                        when 'options'
                            value.my_symbolize_keys(false)

                        else
                            value
                    end

            instance.instance_variable_set( "@#{name}", value )
        end
        instance
    end

    def hash
        to_hash.tap { |h| h.delete :time }.hash
    end

    def ==( other )
        hash == other.hash
    end

end

end
end
end
