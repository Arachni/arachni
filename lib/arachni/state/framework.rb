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

    # @return     [Integer]
    attr_accessor :audited_page_count

    # @return     [Set]
    attr_reader   :browser_skip_states

    # @return     [Symbol]
    attr_accessor :status

    attr_accessor :running

    # @return     [Array]
    attr_reader   :pause_signals

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

        @audited_page_count = 0

        @browser_skip_states = Support::LookUp::HashSet.new( hasher: :persistent_hash )

        @running = false
        @pre_pause_status = nil

        @pause_signals   = Set.new
        @paused_signal    = Queue.new
        @suspended_signal = Queue.new
    end

    # @param    [Support::LookUp::HashSet]  states
    def update_browser_skip_states( states )
        @browser_skip_states.merge states
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

    def running?
        !!@running
    end

    # @param    [Bool]  block
    #   `true` if the method should block until a suspend has completed,
    #   `false` otherwise.
    #
    # @return   [Bool]
    #   `true` if the suspend request was successful, `false` if the system is
    #   already {#suspended?} or is {#suspending?}.
    def suspend( block = true )
        return false if suspended? || suspending?

        @status = :suspending
        @suspend = true

        @suspended_signal.pop if block
        true
    end

    # @return   [Bool]
    #   `true` if a {#suspend} signal is in place , `false` otherwise.
    def suspend?
        !!@suspend
    end

    # Signals a completed suspension.
    def suspended
        @suspend = false
        @status = :suspended
        @suspended_signal << true
        nil
    end

    # @return   [Bool]
    #   `true` if the system has been suspended, `false` otherwise.
    def suspended?
        @status == :suspended
    end

    # @return   [Bool]
    #   `true` if the system is being suspended, `false` otherwise.
    def suspending?
        @status == :suspending
    end

    # @param    [Object]    caller
    #   Identification for the caller which issued the pause signal.
    # @param    [Bool]  block
    #   `true` if the method should block until the pause has completed,
    #   `false` otherwise.
    #
    # @return   [TrueClass]
    #   Pauses the framework on a best effort basis, might take a while to take effect.
    def pause( caller, block = true )
        @pre_pause_status ||= @status if !paused? && !pausing?

        @status = :pausing if !paused?
        @pause_signals << caller

        paused if !running?

        @paused_signal.pop if block && !paused?
        true
    end

    # Signals that the system has been paused..
    def paused
        @status = :paused
        @paused_signal << nil
    end

    # @return   [Bool]
    #   `true` if the framework is paused.
    def paused?
        @status == :paused
    end

    # @return   [Bool]
    #   `true` if the system is being paused, `false` otherwise.
    def pausing?
        @status == :pausing
    end

    # @return   [Bool]
    #   `true` if the framework should pause, `false` otherwise.
    def pause?
        @pause_signals.any?
    end

    # Resumes a paused system
    #
    # @param    [Object]    caller
    #   Identification for the caller whose {#pause} signal to remove. The
    #   system is resumed once there are no more {#pause} signals left.
    #
    # @return   [Bool]
    #   `true` if the system is resumed, `false` if there are more {#pause}
    #   signals pending.
    def resume( caller )
        @pause_signals.delete( caller )

        if @pause_signals.empty?
            @status = @pre_pause_status
            @pre_pause_status = nil
            return true
        end

        false
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
            url_queue_total_size browser_skip_states pause_signals
            audited_page_count).each do |attribute|
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

        framework.audited_page_count =
            Marshal.load( IO.read( "#{directory}/audited_page_count" ) )

        framework.url_queue_filter.merge Marshal.load( IO.read( "#{directory}/url_queue_filter" ) )

        framework.browser_skip_states.merge Marshal.load( IO.read( "#{directory}/browser_skip_states" ) )

        framework.pause_signals.merge Marshal.load( IO.read( "#{directory}/pause_signals" ) )

        framework
    end

    def clear
        rpc.clear

        @pause_signals.clear
        @paused_signal.clear
        @suspended_signal.clear

        @running = false
        @pre_pause_status = nil

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
