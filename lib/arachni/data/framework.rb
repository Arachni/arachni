=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'framework/rpc'

module Arachni
class Data

# Data for {Arachni::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Framework

    # {Framework} error namespace.
    #
    # All {Framework} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Data::Error
    end

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

    def initialize
        @rpc = RPC.new

        @sitemap = {}

        @page_queue            = Support::Database::Queue.new
        @page_queue_filter     = Support::LookUp::HashSet.new( hasher: :persistent_hash )
        @page_queue_total_size = 0

        @url_queue                 = Support::Database::Queue.new
        @url_queue.max_buffer_size = Float::INFINITY

        @url_queue_filter     = Support::LookUp::HashSet.new( hasher: :persistent_hash )
        @url_queue_total_size = 0
    end

    # @note Increases the {#page_queue_total_size}.
    # @note Updates {#page_queue_filter}.
    #
    # @param    [Page]  page
    #   Page to push to the {#page_queue}.
    def push_to_page_queue( page )
        @page_queue << page.clear_cache
        @page_queue_filter << page

        add_page_to_sitemap( page )
        @page_queue_total_size += 1
    end

    # @param    [Page]  page
    # @return    [Bool]
    #   `true` if the `page` has already been seen (based on the
    #   {#page_queue_filter}), `false` otherwise.
    def page_seen?( page )
        @page_queue_filter.include? page
    end

    # @note Increases the {#url_queue_total_size}.
    # @note Updates {#url_queue_filter}.
    #
    # @param    [String]  url
    #   URL to push to the {#url_queue}.
    def push_to_url_queue( url )
        @url_queue << url
        @url_queue_filter << url
        @url_queue_total_size += 1
    end

    # @param    [String]  url
    # @return    [Bool]
    #   `true` if the `url` has already been seen (based on the
    #   {#url_queue_filter}), `false` otherwise.
    def url_seen?( url )
        @url_queue_filter.include? url
    end

    # @param    [Page]  page
    #   Page with which to update the {#sitemap}.
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
            url_queue_total_size).each do |attribute|
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

        framework
    end

    def clear
        rpc.clear

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
