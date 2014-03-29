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

    # @return     [RPC]
    attr_accessor :rpc

    # @return     [Hash<String, Integer>]
    #   List of crawled URLs with their HTTP codes.
    attr_reader   :sitemap

    # @return     [Support::Database::Queue]
    attr_reader   :page_queue

    # @return     [Support::LookUp::HashSet]
    attr_reader   :page_queue_filter

    # @return     [Integer]
    attr_accessor :page_queue_total_size

    # @return     [Support::Database::Queue]
    attr_reader   :url_queue

    # @return     [Support::LookUp::HashSet]
    attr_reader   :url_queue_filter

    # @return     [Integer]
    attr_accessor :url_queue_total_size

    # @return     [Set]
    attr_reader   :browser_skip_states

    def initialize
        @rpc = RPC.new

        @sitemap = {}

        @page_queue            = Support::Database::Queue.new
        @page_queue_filter     = Support::LookUp::HashSet.new( hasher: :persistent_hash )
        @page_queue_total_size = 0

        @url_queue            = Support::Database::Queue.new
        @url_queue.max_buffer_size = Float::INFINITY

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

    def dump( directory )
        FileUtils.mkdir_p( directory )

        rpc.dump( "#{directory}/rpc/" )

        page_queue_directory = "#{directory}/page_queue/"

        FileUtils.rm_rf( page_queue_directory )
        FileUtils.mkdir_p( page_queue_directory )

        page_queue.buffer.each do |page|
            File.open( "#{page_queue_directory}/#{page.persistent_hash}", 'w' ) do |f|
                f.write Marshal.dump( page )
            end
        end
        page_queue.disk.each do |filepath|
            FileUtils.cp filepath, "#{page_queue_directory}/"
        end

        File.open( "#{directory}/url_queue", 'w' ) do |f|
            f.write Marshal.dump( @url_queue.buffer )
        end

        %w(sitemap page_queue_filter page_queue_total_size url_queue_filter
            url_queue_total_size browser_skip_states).each do |attribute|
            File.open( "#{directory}/#{attribute}", 'w' ) do |f|
                f.write Marshal.dump( send(attribute) )
            end
        end
    end

    def self.load( directory )
        framework = new

        framework.rpc = RPC.load( "#{directory}/rpc/" )
        framework.sitemap.merge! Marshal.load( IO.read( "#{directory}/sitemap" ) )

        Dir["#{directory}/page_queue/*"].each do |page_file|
            framework.page_queue.disk << page_file
        end

        Marshal.load( IO.read( "#{directory}/url_queue" ) ).each do |url|
            framework.url_queue.buffer << url
        end

        framework.page_queue_total_size =
            Marshal.load( IO.read( "#{directory}/page_queue_total_size" ) )

        framework.page_queue_filter.merge Marshal.load( IO.read( "#{directory}/page_queue_filter" ) )

        framework.url_queue_total_size =
            Marshal.load( IO.read( "#{directory}/url_queue_total_size" ) )

        framework.url_queue_filter.merge Marshal.load( IO.read( "#{directory}/url_queue_filter" ) )

        framework.browser_skip_states.merge Marshal.load( IO.read( "#{directory}/browser_skip_states" ) )

        framework
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
