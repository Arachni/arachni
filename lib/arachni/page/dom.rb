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
    #   {JavaScript::TaintTracer#data_flow_sink} data.
    attr_accessor :data_flow_sink

    # @return   [Array]
    #   {JavaScript::TaintTracer#execution_flow_sink} data.
    attr_accessor :execution_flow_sink

    # @return   [String]
    #   URL of the page as seen by the user-agent, fragments and all.
    attr_accessor :url

    # @param    [Hash]  options
    # @option   options [Page]  :page
    # @option   options [Array<Hash>]  :transitions
    def initialize( options )
        @page                = options[:page]
        @url                 = options[:url]                 || @page.url.dup
        @transitions         = options[:transitions]         || []
        @data_flow_sink      = options[:data_flow_sink]      || []
        @execution_flow_sink = options[:execution_flow_sink] || []
        @skip_states         = options[:skip_states]         ||
            Support::LookUp::HashSet.new( hasher: :persistent_hash )
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

    # @return   [Hash]
    def to_h
        {
            url:                 @url,
            transitions:         @transitions,
            skip_states:         @skip_states,
            data_flow_sink:      @data_flow_sink,
            execution_flow_sink: @execution_flow_sink
        }
    end

    def hash
        @hash ||= rehash
    end

    def ==( other )
        hash == other.hash
    end

    # @private
    def clear_caches
        @hash = nil
    end

    private

    def rehash
        hash = ''
        @page.document.traverse do |node|
            next if IGNORE_FROM_HASH.include? node.name
            hash << node.name
            hash << attributes_to_str( node )
        end

        hash.persistent_hash
    end

    def attributes_to_str( node )
        node.attributes.inject({}){ |h, (name, attr)| h[name] = attr.value; h }.
            sort.to_s
    rescue NoMethodError
        ''
    end

end

end
end
