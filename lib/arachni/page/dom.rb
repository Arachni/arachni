=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Page

# Static DOM snapshot as computed by a real browser.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class DOM

    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Page::Error
    end

    require_relative 'dom/transition'

    # Ignore these elements when calculating a {#hash}.
    IGNORE_FROM_HASH = Set.new([ 'text', 'p' ])

    # @return   [Support::LookUp::HashSet]
    attr_accessor :skip_states

    # @return   [Array<Transition>]
    #   Transitions representing the steps required to convert a {DOM}
    #   snapshot to a live {Browser} page.
    attr_accessor :transitions

    # @return   [Array]
    #   {Browser::Javascript::TaintTracer#data_flow_sinks} data.
    attr_accessor :data_flow_sinks

    # @return   [Array]
    #   {Browser::Javascript::TaintTracer#execution_flow_sinks} data.
    attr_accessor :execution_flow_sinks

    # @return   [String]
    #   String digest of the DOM tree.
    attr_accessor :digest

    # @return   [String]
    #   URL of the page as seen by the user-agent, fragments and all.
    attr_accessor :url

    # @return   [Page]
    #   Page to which this DOM state is attached.
    attr_reader   :page

    # @param    [Hash]  options
    # @option   options [Page]  :page
    # @option   options [Array<Hash>]  :transitions
    def initialize( options )
        @page                 = options[:page]
        self.url              = options[:url]                   || @page.url
        self.digest           = options[:digest]
        @transitions          = options[:transitions]           || []
        @data_flow_sinks      = options[:data_flow_sinks]       || []
        @execution_flow_sinks = options[:execution_flow_sinks]  || []
        @skip_states          = options[:skip_states]           ||
            Support::LookUp::HashSet.new( hasher: :persistent_hash )
    end

    def url=( url )
        @url = url.freeze
    end

    def digest=( d )
        return @digest = nil if !d

        normalized_url = Utilities.normalize_url( url )

        if d.include?( url ) || d.include?( normalized_url )
            d = d.dup
            d.gsub!( url, '' )
            d.gsub!( normalized_url, '' )
        end

        @digest = d.freeze
    end

    # @param    [Transition]    transition
    #   Push the given transition to the {#transitions}.
    def push_transition( transition )
        @transitions << transition
    end

    # @return   [Integer]
    #   Depth of the current DOM -- sum of {#transitions} {Transition#depth}s
    #   that had to be triggered to reach the current state.
    def depth
        @transitions.map { |t| t.depth }.inject(&:+).to_i
    end

    def playable_transitions
        transitions.select { |t| t.playable? }
    end

    def print_transitions( printer, indent = '' )
        longest_event_size = 0
        @transitions.each do |t|
            longest_event_size = [t.event.to_s.size, longest_event_size].max
        end

        @transitions.map do |t|
            padding = longest_event_size - t.event.to_s.size + 1
            time    = sprintf( '%.4f', t.time.to_f )

            if t.event == :request
                printer.call "#{indent * 2}* [#{time}s] #{t.event}#{' ' * padding} => #{t.element}"
            else
                url = nil
                if t.options[:url]
                    url = "(#{t.options[:url]})"
                end

                printer.call "#{indent}-- [#{time}s] #{t.event}#{' ' * padding} => #{t.element} #{url}"

                if t.options[:cookies] && t.options[:cookies].any?
                    printer.call "#{indent * 2}-- Cookies:"

                    t.options[:cookies].each do |name, value|
                        printer.call  "#{indent * 3}* #{name}\t=> #{value}\n"
                    end
                end

                if t.options[:inputs] && t.options[:inputs].any?
                    t.options[:inputs].each do |name, value|
                        printer.call  "#{indent * 2}* #{name}\t=> #{value}\n"
                    end
                end
            end
        end
    end

    # Loads the page and restores it to its captured state.
    #
    # @param    [Browser]   browser
    #   Browser to use to restore the DOM.
    #
    # @return   [Browser, nil]
    #   Live page in the `browser` if successful, `nil` otherwise.
    def restore( browser, take_snapshot = true )
        # First, try to load the page via its DOM#url in case it can restore
        # itself via its URL fragments and whatnot.
        browser.goto url, take_snapshot: take_snapshot

        playables = self.playable_transitions

        # If we've got no playable transitions then we're done.
        return browser if playables.empty?

        browser_dom = browser.state

        # We were probably led to an out-of-scope page via a JS redirect, bail out.
        return if !browser_dom

        # Check to see if just loading the DOM URL was enough.
        #
        # Of course, this check will fail some of the time because even if the
        # page can restore itself via its URL (using fragment data most probably),
        # the document may still be different from when our snapshot was captured.
        #
        # However, this check doesn't cost us much so it's worth a shot.
        if browser_dom === self
            browser.print_debug "Loaded snapshot by URL: #{url}"
            return browser
        end

        browser.print_debug "Could not load snapshot by URL (#{url}), " <<
            'will load by replaying transitions.'

        # The URL restore failed, replay its transitions.
        playables.each do |transition|
            next if transition.play( browser )

            browser.print_debug "Could not replay transition for: #{url}"
            playables.each do |t|
                browser.print_debug "-#{t == transition ? '>' : '-'} #{transition}"
            end

            return
        end

        browser
    end

    def state
        self.class.new(
            url:         @url,
            digest:      @digest,
            transitions: @transitions.dup,
            skip_states: @skip_states.dup
        )
    end

    # @return   [Hash]
    def to_h
        {
            url:                  url,
            transitions:          transitions.map(&:to_hash),
            digest:               digest,
            skip_states:          skip_states,
            data_flow_sinks:      data_flow_sinks.map(&:to_hash),
            execution_flow_sinks: execution_flow_sinks.map(&:to_hash)
        }
    end
    def to_hash
        to_h
    end

    def to_s
        s = "#<#{self.class}:#{object_id} "
        s << "@url=#{@url.inspect} "
        s << "@transitions=#{transitions.size} "
        s << "@data_flow_sinks=#{@data_flow_sinks.size} "
        s << "@execution_flow_sinks=#{@execution_flow_sinks.size}"
        s << '>'
    end
    alias :inspect :to_s

    # @return   [Hash]
    #   Data representing this instance that are suitable the RPC transmission.
    def to_rpc_data
        {
            'url'                  => url,
            'transitions'          => transitions.map(&:to_rpc_data),
            'digest'               => digest,
            'skip_states'          => skip_states ? skip_states.collection.to_a : [],
            'data_flow_sinks'      => data_flow_sinks.map(&:to_rpc_data),
            'execution_flow_sinks' => execution_flow_sinks.map(&:to_rpc_data)
        }
    end

    # @param    [Hash]  data
    #   {#to_rpc_data}
    # @return   [DOM]
    def self.from_rpc_data( data )
        instance = allocate
        data.each do |name, value|

            value = case name
                        when 'transitions'
                            value.map { |t| Transition.from_rpc_data t }

                        when 'data_flow_sinks'
                            value.map do |entry|
                                Browser::Javascript::TaintTracer::Sink::DataFlow.from_rpc_data( entry )
                            end.to_a

                        when 'execution_flow_sinks'
                            value.map do |entry|
                                Browser::Javascript::TaintTracer::Sink::ExecutionFlow.from_rpc_data( entry )
                            end.to_a

                        when 'skip_states'
                            skip_states = Support::LookUp::HashSet.new(
                                hasher: :persistent_hash
                            )
                            skip_states.collection.merge( value || [] )
                            skip_states

                        else
                            value
                    end

            instance.instance_variable_set( "@#{name}", value )
        end
        instance
    end

    def hash
        # TODO: Maybe raise error if #digest is not set?
        digest.persistent_hash
    end

    def ==( other )
        hash == other.hash
    end

    # @note Removes the URL strings of both DOMs from each other's document
    #        before comparing.
    #
    # @param    [DOM]   other
    # @return   [Bool]
    #   `true` if the compared DOM trees are effectively the same, `false` otherwise.
    def ===( other )
        digest_without_urls( other ) == other.digest_without_urls( self )
    end

    protected

    def digest_without_urls( dom )
        normalized_other_url = Utilities.normalize_url( dom.url )

        if !digest.include?( dom.url ) &&
            !digest.include?( normalized_other_url )
            return digest
        end

        d = digest.dup
        d.gsub!( dom.url, '' )
        d.gsub!( normalized_other_url, '' )
        d
    end

end

end
end
