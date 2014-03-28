=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'framework/rpc'

module Arachni
class State

# State information for {Arachni::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Framework

    # @return   [RPC]
    attr_reader :rpc

    # @return   [Hash<String, Integer>]
    #   List of crawled URLs with their HTTP codes.
    attr_reader :sitemap

    # @return   [Support::Database::Queue]
    attr_reader :page_queue

    # @return   [Support::LookUp::HashSet]
    attr_reader :page_queue_filter

    # @return   [Integer]
    attr_reader :page_queue_total_size

    # @return   [Queue]
    attr_reader :url_queue

    # @return   [Support::LookUp::HashSet]
    attr_reader :url_queue_filter

    # @return   [Integer]
    attr_reader :url_queue_total_size

    # @return   [Set]
    attr_reader :browser_skip_states

    def initialize
        @rpc = RPC.new

        @sitemap = {}

        @page_queue            = Support::Database::Queue.new
        @page_queue_filter     = Support::LookUp::HashSet.new( hasher: :persistent_hash )
        @page_queue_total_size = 0

        @url_queue            = Queue.new
        @url_queue_filter     = Support::LookUp::HashSet.new( hasher: :persistent_hash )
        @url_queue_total_size = 0

        @browser_skip_states = Set.new
    end

    def update_browser_skip_states( states )
        @browser_skip_states |= states
    end

    def push_to_page_queue( page )
        @page_queue << page.clear_cache
        @page_queue_filter << page

        add_page_to_sitemap( page )
        @page_queue_total_size += 1
    end

    def page_seen?( page )
        @page_queue_filter.include? page
    end

    def push_to_url_queue( url )
        @url_queue << url
        @url_queue_filter << url
        @url_queue_total_size += 1
    end

    def url_seen?( url )
        @url_queue_filter.include? url
    end

    def add_page_to_sitemap( page )
        sitemap[page.dom.url] = page.code
    end

    def clear
        rpc.clear
        @browser_skip_states.clear
        @sitemap.clear

        @page_queue.clear
        @page_queue_filter.clear
        @page_queue_total_size = 0

        @url_queue.clear
        @url_queue_filter.clear
        @url_queue_total_size = 0
    end

end

end
end
