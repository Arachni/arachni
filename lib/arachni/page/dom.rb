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

    # Ignore these elements when calculating a {#hash}.
    IGNORE_FROM_HASH = Set.new([ 'text', 'p' ])

    # @return   [Array<Hash{Symbol => <Symbol,String>}>]
    #   DOM transitions leading to the current state.
    attr_accessor :transitions

    # @return   [String]
    #   URL of the page as seen by the user-agent, fragments and all.
    attr_accessor :url

    # @param    [Hash]  options
    # @option   options [Page]  :page
    # @option   options [Array<Hash>]  :transitions
    def initialize( options )
        @page        = options[:page]
        @url         = options[:url]         || @page.url.dup
        @transitions = options[:transitions] || []
    end

    # @param    [Hash{Symbol => <Symbol,String>}]    transition
    #   Push the given transition to the DOM with element at key and the event
    #   as value.
    def push_transition( transition )
        @transitions << transition
    end

    # @return   [Integer]
    #   Depth of the current DOM -- amount of events that had to be triggered
    #   to reach the current state.
    def depth
        @transitions.select { |t| t.values.first != :request }.size
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
