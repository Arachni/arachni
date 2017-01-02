=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'framework/rpc'

module Arachni
class Data

# Data for {Arachni::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Framework

    # {Framework} error namespace.
    #
    # All {Framework} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Data::Error
    end

    # @return     [RPC]
    attr_accessor :rpc

    # @return     [Hash<String, Integer>]
    #   List of crawled URLs with their HTTP codes.
    attr_reader   :sitemap

    # @return     [Support::Database::Queue]
    attr_reader   :page_queue

    # @return     [Integer]
    attr_accessor :page_queue_total_size

    # @return     [Support::Database::Queue]
    attr_reader   :url_queue

    # @return     [Integer]
    attr_accessor :url_queue_total_size

    def initialize
        @rpc = RPC.new

        @sitemap = {}

        @page_queue            = Support::Database::Queue.new
        @page_queue.max_buffer_size = 10
        @page_queue_total_size = 0

        @url_queue                 = Support::Database::Queue.new
        @url_queue.max_buffer_size = Float::INFINITY
        @url_queue_total_size      = 0
    end

    def statistics
        {
            rpc:                   @rpc.statistics,
            sitemap:               @sitemap.size,
            page_queue:            @page_queue.size,
            page_queue_total_size: @page_queue_total_size,
            url_queue:             @url_queue.size,
            url_queue_total_size:  @url_queue_total_size
        }
    end

    # @note Increases the {#page_queue_total_size}.
    #
    # @param    [Page]  page
    #   Page to push to the {#page_queue}.
    def push_to_page_queue( page )
        @page_queue << page.clear_cache
        add_page_to_sitemap( page )
        @page_queue_total_size += 1
    end

    # @note Increases the {#url_queue_total_size}.
    #
    # @param    [String]  url
    #   URL to push to the {#url_queue}.
    def push_to_url_queue( url )
        @url_queue << url
        @url_queue_total_size += 1
    end

    # @param    [Page]  page
    #   Page with which to update the {#sitemap}.
    def add_page_to_sitemap( page )
        update_sitemap( page.dom.url => page.code )
    end

    def update_sitemap( entries )
        entries.each do |url, code|
            # Feedback from the trainer or whatever, don't include it in the
            # sitemap, it'll just add noise.
            next if url.include?( Utilities.random_seed )

            @sitemap[url] = code
        end

        @sitemap
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        rpc.dump( "#{directory}/rpc/" )

        page_queue_directory = "#{directory}/page_queue/"

        FileUtils.rm_rf( page_queue_directory )
        FileUtils.mkdir_p( page_queue_directory )

        page_queue.buffer.each do |page|
            IO.binwrite(
                "#{page_queue_directory}/#{page.persistent_hash}",
                 Marshal.dump( page )
            )
        end

        page_queue.disk.each do |filepath|
            FileUtils.cp filepath, "#{page_queue_directory}/"
        end

        IO.binwrite( "#{directory}/url_queue", Marshal.dump( @url_queue.buffer ) )

        %w(sitemap page_queue_total_size url_queue_total_size).each do |attribute|
            IO.binwrite( "#{directory}/#{attribute}", Marshal.dump( send(attribute) ) )
        end
    end

    def self.load( directory )
        framework = new

        framework.rpc = RPC.load( "#{directory}/rpc/" )
        framework.sitemap.merge! Marshal.load( IO.binread( "#{directory}/sitemap" ) )

        Dir["#{directory}/page_queue/*"].each do |page_file|
            framework.page_queue.disk << page_file
        end

        Marshal.load( IO.binread( "#{directory}/url_queue" ) ).each do |url|
            framework.url_queue.buffer << url
        end

        framework.page_queue_total_size =
            Marshal.load( IO.binread( "#{directory}/page_queue_total_size" ) )
        framework.url_queue_total_size =
            Marshal.load( IO.binread( "#{directory}/url_queue_total_size" ) )

        framework
    end

    def clear
        rpc.clear

        @sitemap.clear

        @page_queue.clear
        @page_queue_total_size = 0

        @url_queue.clear
        @url_queue_total_size = 0
    end

end

end
end
