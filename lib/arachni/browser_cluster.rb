=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

lib = Options.dir['lib']
require lib + 'browser'
require lib + 'rpc/server/browser'

# Real browser driver providing DOM/JS/AJAX support.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class BrowserCluster
    include UI::Output
    include Utilities

    # {BrowserCluster} error namespace.
    #
    # All {BrowserCluster} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Arachni::Error

        # Raised when a method is called after the {BrowserCluster} has been
        # {BrowserCluster#shutdown}.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class AlreadyShutdown < Error
        end
    end

    DEFAULT_OPTIONS = {
        # Amount of Browsers to keep in the pool and put to work. 6 seems to
        # be the magic number, 1 to go over all elements and generate the workload
        # and 5 to pop the work from the queue and get to it.
        #
        # It's diminishing returns past that point, even with more workload
        # generators and more workers.
        pool_size:    6,

        # Lifetime of each Browser counted in pages.
        time_to_live: 10
    }

    # @return   [Integer]   Amount of browser instances in the pool.
    attr_reader :pool_size

    # @return   [Hash<String, Integer>]
    #   List of crawled URLs with their HTTP codes.
    attr_reader :sitemap

    # @param    [Hash]  options
    # @option   options [Integer]   :pool_size (5)
    #   Amount of {RPC::Server::Browser browsers} to add to the pool.
    # @option   options [Integer]   :time_to_live (10)
    #   Restricts each browser's lifetime to the given amount of pages.
    #   When that number is exceeded the current process is killed and a new
    #   one is pushed to the pool. Helps prevent memory leak issues.
    # @option   [Proc]  :handler
    #   `Proc` to handle each page returned by {RPC::Server::Browser#analyze}.
    #
    # @raise    ArgumentError   On missing `:handler` option.
    def initialize( options = {} )
        DEFAULT_OPTIONS.merge( options ).each do |k, v|
            begin
                send( "#{k}=", try_dup( v ) )
            rescue NoMethodError
                instance_variable_set( "@#{k}".to_sym, v )
            end
        end

        fail ArgumentError, 'Missing :handler option.' if !@handler

        # Used to sync operations between browser workers.
        @skip = Support::LookUp::HashSet.new( hasher: :persistent_hash )

        # Holds resources to consume, Arachni::Page objects usually.
        @resources = Support::Database::Queue.new
        @sitemap   = {}
        @mutex     = Mutex.new

        initialize_browsers

        start
    end

    # @param    [Page, String, HTTP::Response]  resource
    #   Resource to analyze, if given a `String` it will treat it as a URL.
    def analyze( resource )
        fail_if_shutdown

        @resources << resource
        true
    end

    # @return   [Bool]
    #   `true` if there are no resources to analyze and no running workers.
    def done?
        fail_if_shutdown

        synchronize do
            @resources.empty? && @browsers[:busy].empty?
        end
    end

    # Blocks until all resources have been analyzed.
    def wait
        fail_if_shutdown

        sleep 0.1 while !done?
        self
    end

    # Shuts the cluster down.
    def shutdown
        return false if !@running

        @running = false

        # Kill the resource consumer thread.
        @worker.kill

        # Clear the temp files used to hold the resources to analyze.
        @resources.clear

        # Kill the browsers.
        q = Queue.new
        (@browsers[:idle] | @browsers[:busy]).each { |b| b.shutdown { q << nil } }
        pool_size.times { q.pop }

        # Kill our IPC RPC server.
        @servers.map( &:shutdown )

        true
    end

    # Used to sync operations between browser workers.
    #
    # @param    [String]    action  Should the given action be skipped?
    # @private
    def skip?( action )
        synchronize { @skip.include? action }
    end

    # Used to sync operations between browser workers.
    #
    # @param    [String]    action  Action to skip in the future.
    # @private
    def skip( action )
        synchronize { @skip << action }
    end

    # Passes the `page` to the handler.
    #
    # @param    [Page]  page
    def handle_page( page )
        fail_if_shutdown

        synchronize do
            exception_jail( false ){ @handler.call page }
        end
    end

    def push_to_sitemap( url, code )
        synchronize { @sitemap[url] = code }
    end

    def alive?
        true
    end

    private

    def fail_if_shutdown
        fail Error::AlreadyShutdown, 'Cluster has been shut down.' if !@running
    end

    def start
        Thread.abort_on_exception = true

        @running = true
        @worker  = Thread.new do
            while @running do
                sleep 0.05
                next if @resources.empty?

                synchronize do
                    next if @browsers[:idle].empty?

                    browser = @browsers[:idle].pop
                    @browsers[:busy] << browser

                    browser.analyze(
                        @resources.pop,
                        cookies: HTTP::Client.cookies
                    ){ move_browser( browser, :busy, :idle ) }
                end
            end
        end
    end

    def ipc_handle
        socket = "/tmp/arachni-browser-cluster-#{Utilities.available_port}"
        token = Utilities.generate_token

        @servers ||= []

        server = RPC::Server::Base.new( { rpc_socket: socket }, token )
        @servers << server

        server.logger.level = ::Logger::Severity::FATAL
        server.add_handler( 'cluster', self )

        RPC::EM.schedule { server.start }
        sleep 0.1 while !File.exists?( socket )

        handler = RPC::RemoteObjectMapper.new(
            RPC::Client::Base.new( Options.instance, socket, token ),
            'cluster'
        )

        wait_till_service_ready handler
        handler
    end

    def move_browser( browser, from_state, to_state )
        synchronize { @browsers[to_state] << @browsers[from_state].delete( browser ) }
    end

    def synchronize( &block )
        @mutex.synchronize( &block )
    end

    def initialize_browsers
        @browsers  = {
            idle: [],
            busy: []
        }

        js_token         = Utilities.generate_token
        booting_browsers = []

        pool_size.times do
            booting_browsers << RPC::Server::Browser.spawn(
                js_token: js_token,
                master:   ipc_handle
            )
        end

        begin
            Timeout.timeout( 10 ) do
                loop do
                    booting_browsers.each do |socket, token|
                        begin
                            b = RPC::Client::Browser.new( socket, token )
                            b.alive?
                            booting_browsers.delete( [socket, token] )
                            @browsers[:idle] << b
                        rescue
                        end
                    end
                    break if booting_browsers.empty?
                end
            end
        rescue Timeout::Error
            abort 'BrowserCluster failed to initialize peers in time.'
        end
    end

    def wait_till_service_ready( service )
        begin
            Timeout.timeout( 10 ) do
                while sleep( 0.1 )
                    begin
                        service.alive?
                        break
                    rescue ::RPC::Exceptions::ConnectionError
                    end
                end
            end
        rescue Timeout::Error
            abort 'BrowserCluster never started!'
        end
    end

end
end
