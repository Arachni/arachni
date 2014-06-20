=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class Page

# Static DOM snapshot as computed by a real browser.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DOM

    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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
    #   {Browser::Javascript::TaintTracer#data_flow_sink} data.
    attr_accessor :data_flow_sink

    # @return   [Array]
    #   {Browser::Javascript::TaintTracer#execution_flow_sink} data.
    attr_accessor :execution_flow_sink

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
        @page                = options[:page]
        self.url             = options[:url]                 || @page.url
        self.digest          = options[:digest]
        @transitions         = options[:transitions]         || []
        @data_flow_sink      = options[:data_flow_sink]      || []
        @execution_flow_sink = options[:execution_flow_sink] || []
        @skip_states         = options[:skip_states]         ||
            Support::LookUp::HashSet.new( hasher: :persistent_hash )
    end

    def url=( url )
        @url = url.freeze
    end

    def digest=( digest )
        return @digest = nil if !digest
        @digest = digest.freeze
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
        page.dom.transitions.each do |t|
            longest_event_size = [t.event.to_s.size, longest_event_size].max
        end

        page.dom.transitions.map do |t|
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

                    t.options[:cookies].each do |cookie|
                        printer.call  "#{indent * 3}* #{cookie.name}\t=> #{cookie.value}\n"
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
        # Preload the associated HTTP response since we've already got it.
        browser.preload( page )

        # First, try to load the page via its DOM#url in case it can restore
        # itself via its URL fragments and whatnot.
        browser.goto url, take_snapshot: take_snapshot

        playables = playable_transitions

        # If we've got no playable transitions then we're done.
        return browser if playables.empty?

        browser_page = browser.to_page

        # We were probably led to an out-of-scope page via a JS redirect,
        # bail out.
        return if !browser_page

        # Check to see if just loading the DOM URL was enough.
        #
        # Of course, this check will fail some of the time because even if the
        # page can restore itself via its URL (using fragment data most probably),
        # the document may still be different from when our snapshot was captured.
        #
        # However, this check doesn't cost us much so it's worth a shot.
        if browser_page.dom === self
            return browser
        end

        # The URL restore failed, so, navigate to the pure version of the URL and
        # replay its transitions.
        browser.preload( page )

        playables.each do |transition|
            next if transition.play( browser )

            browser.print_error "Could not replay transition for: #{url}"
            playables.each do |t|
                browser.print_error "-#{t == transition ? '>' : '-'} #{transition}"
            end

            return
        end

        browser
    end

    # @return   [Hash]
    def to_h
        {
            url:                 url,
            transitions:         transitions.map(&:to_hash),
            digest:              digest,
            skip_states:         skip_states,
            data_flow_sink:      data_flow_sink.map(&:to_hash),
            execution_flow_sink: execution_flow_sink.map(&:to_hash)
        }
    end
    def to_hash
        to_h
    end

    # @return   [Hash]
    #   Data representing this instance that are suitable the RPC transmission.
    def to_rpc_data
        {
            'url'                 => url,
            'transitions'         => transitions.map(&:to_rpc_data),
            'digest'              => digest,
            'skip_states'         => skip_states ? skip_states.collection.to_a : [],
            'data_flow_sink'      => data_flow_sink.map(&:to_rpc_data),
            'execution_flow_sink' => execution_flow_sink.map(&:to_rpc_data)
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

                        when 'data_flow_sink'
                            value.map do |entry|
                                Browser::Javascript::TaintTracer::Sink::DataFlow.from_rpc_data( entry )
                            end.to_a

                        when 'execution_flow_sink'
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

    def digest_without_urls( other )
        digest.gsub( url, '' ).gsub( other.url, '' ).
            gsub( page.url, '' ).gsub( other.page.url, '' )
    end

end

end
end
