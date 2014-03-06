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

    attr_reader   :page

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

    def playable_transitions
        transitions.select { |t| t.playable? }
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
        browser.preload( @page )

        # First, try to load the page via its DOM#url in case it can restore
        # itself via its URL fragments and whatnot.
        browser.goto url, take_snapshot

        playables = playable_transitions

        # If we've got no playable transitions then we're done.
        return browser if playables.empty?

        page = browser.to_page

        # We were probably led to an out-of-scope page via a JS redirect,
        # bail out.
        return if !page

        # Check to see if just loading the DOM URL was enough.
        #
        # Of course, this check will fail some of the time because even if the
        # page can restore itself via its URL (using fragment data most probably),
        # the document may still be different from when our snapshot was captured.
        #
        # However, this check doesn't cost us much so it's worth a shot.
        if page.dom === self
            #ap "RESTORED BY URL: #{url}"
            return browser
        end

        #if page.dom.url == url
        #    ap '-' * 100
        #
        #    ap page.dom.url
        #    ap url
        #
        #    page_body_lines = @page.body.gsub(url, '').lines
        #    page.body.gsub(url, '').lines.each.with_index do |line, i|
        #        next if line == page_body_lines[i]
        #
        #        ap i
        #        puts "  #{line}"
        #        puts "  #{page_body_lines[i]}"
        #
        #        next if !page_body_lines[i]
        #        puts
        #        puts "  #{line.gsub( url, '' ).gsub( page.dom.url, '' )}"
        #        puts "  #{page_body_lines[i].gsub( url, '' ).gsub( page.dom.url, '' )}"
        #    end
        #
        #    puts string_digest.gsub( url, '' ).gsub( page.dom.url, '' )
        #    puts
        #    puts page.dom.string_digest.gsub( url, '' ).gsub( page.dom.url, '' )
        #
        #    ap '-' * 100
        #end

        # The URL restore failed so navigate to the pure version of the URL and
        # replay its transitions.
        #
        # Thankfully, all external resources will have been cached from the
        # previous attempt at restoring the page, so this operation shouldn't
        # cause much overhead.
        browser.preload( @page )
        browser.goto page.url, take_snapshot

        playables.each do |transition|
            next if transition.play( browser )

            browser.print_error "Could not replay transition for: #{url}"
            playables.each do |t|
                browser.print_error "-#{t == transition ? '>' : '-'} #{transition}"
            end

            return
        end

        #ap "RESTORED BY TRANSITIONS: #{url}"

        browser
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

    # @note Removes the URL strings of both DOMs from each other's document
    #        before comparing.
    #
    # @param    [DOM]   other
    # @return   [Bool]
    #   `true` if the compared DOM trees are effectively the same, `false` otherwise.
    def ===( other )
        digest_without_urls( other ) == other.digest_without_urls( self )
    end

    # @private
    def clear_caches
        @hash = nil
    end

    protected

    def digest_without_urls( other )
        string_digest.gsub( url, '' ).gsub( other.url, '' ).
            gsub( page.url, '' ).gsub( other.page.url, '' )
    end

    def string_digest
        digest = ''
        @page.document.traverse do |node|
            next if IGNORE_FROM_HASH.include? node.name
            digest << node.name
            digest << attributes_to_str( node )
        end
        digest
    end

    private

    def rehash
        string_digest.persistent_hash
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
