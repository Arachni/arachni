=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end


module Arachni

lib = Options.paths.lib
require lib + 'browser'
require lib + 'rpc/server/base'
require lib + 'rpc/client/browser_cluster/peer'
require lib + 'processes'
require lib + 'framework'

class BrowserCluster

# Overrides some {Arachni::Browser} methods to make multiple browsers play well
# with each other when they're part of a {BrowserCluster}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Peer < Arachni::Browser

    # Spawns a {Peer} in it own process and connects to it.
    #
    # @param    [Hash]  options
    # @option   options  :wait [Bool]
    #   `true` to wait until the {Browser} has booted, `false` otherwise.
    #
    # @return   [Array, RPC::Client::BrowserCluster::Peer]
    #
    #   * `[socket, token]` if `:wait` has been set to `false`.
    #   * {RPC::Client::BrowserCluster::Peer} if `:wait` has been set to `true`.
    def self.spawn( options = {} )
        socket = "/tmp/arachni-browser-#{Utilities.available_port}"
        token  = Utilities.generate_token

        ::EM.fork_reactor do
            Options.rpc.server_socket = socket
            new(
                master:           options[:master],
                token:            token,
                javascript_token: options[:javascript_token]
            )
        end

        if options[:wait]
            sleep 0.1 while !File.exists?( socket )

            client = RPC::Client::BrowserCluster::Peer.new( socket, token )
            begin
                Timeout.timeout( 10 ) do
                    while sleep( 0.1 )
                        begin
                            client.alive?
                            break
                        rescue Exception
                        end
                    end
                end
            rescue Timeout::Error
                abort "Browser '#{socket}' never started!"
            end

            return client
        end

        [socket, token]
    end

    # @return    [RPC::RemoteObjectMapper]    For {BrowserCluster}.
    attr_reader :master

    # @return [Job] Currently assigned job.
    attr_reader :job

    def initialize( options )
        %w(QUIT INT).each do |signal|
            trap( signal, 'IGNORE' ) if Signal.list.has_key?( signal )
        end

        rpc_auth_token   = options.delete( :token )
        javascript_token = options.delete( :javascript_token )
        @master          = options.delete( :master )

        # Don't store pages if there's a master, we'll be sending them to him
        # as soon as they're logged.
        super options.merge( store_pages: false )

        @javascript.token = javascript_token

        start_capture

        @server = RPC::Server::Base.new( Options.instance, rpc_auth_token )
        @server.logger.level = ::Logger::Severity::FATAL

        @server.add_async_check do |method|
            # Methods that expect a block are async.
            method.parameters.flatten.include? :block
        end

        @server.add_handler( 'browser', self )
        @server.start
    end

    # @param    [BrowserCluster::Job]  job
    # @param    [Hash]  options
    # @option   options [Array<Cookie>] :cookies
    #   Cookies with which to update the browser's cookie-jar before analyzing
    #   the given resource.
    #
    # @return   [Array<Page>]
    #   Pages which resulted from firing events, clicking JavaScript links
    #   and capturing AJAX requests.
    #
    # @see Arachni::Browser#trigger_events
    def run_job( job, options = {}, &block )
        HTTP::Client.update_cookies( options[:cookies] || [] )

        @job = job

        ::EM.defer do
            begin
                @job.configure_and_run( self )
            rescue => e
                print_error e
                print_error_backtrace e
            end

            # The jobs may have configured callbacks to capture pages etc.,
            # remove them.
            @on_new_page_blocks.clear
            @on_new_page_with_sink_blocks.clear
            @on_response_blocks.clear

            # Close open windows to free system resources and have a clean
            # slate for the later job.
            close_windows

            @job = nil
            block.call
        end

        true
    end

    # Let the master handle deduplication of operations.
    #
    # @see Browser#skip?
    def skip?( action )
        master.skip? job.id, action
    end

    # Let the master know that the given operation should be skipped in
    # the future.
    #
    # @see Browser#skip
    def skip( action )
        master.skip job.id, action
    end

    # We change the default scheduling to distribute elements and events
    # to all available browsers ASAP, instead of building a list and then
    # consuming it, since we're don't have to worry about messing up our
    # page's state in this setup.
    #
    # @see Browser#trigger_events
    def trigger_events
        root_page = to_page

        each_element_with_events do |info|
            info[:events].each do |name, _|
                distribute_event( root_page, info[:index], name.to_sym )
            end
        end

        true
    end

    # Direct the distribution to the master and let it take it from there.
    #
    # @see Jobs::EventTrigger
    # @see BrowserCluster#queue
    def distribute_event( page, element_index, event )
        master.queue @job.forward_as(
            @job.class::EventTrigger,
            {
                resource:      page,
                element_index: element_index,
                event:         event
            }
        )
        true
    rescue Job::Error::AlreadyDone
        false
    end

    # @return   [Bool]  `true`
    def alive?
        true
    end

    # Closes the browser and shuts down the server.
    def shutdown
        super
        @server.shutdown rescue nil
        nil
    end

    private

    def save_response( response )
        super( response )
        @master.push_to_sitemap( response.url, response.code ){}
        response
    end

end
end
end
