=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require 'ostruct'

module Arachni

require Options.dir['lib'] + 'rpc/client/instance'
require Options.dir['lib'] + 'rpc/client/dispatcher'

require Options.dir['lib'] + 'rpc/server/base'
require Options.dir['lib'] + 'rpc/server/output'
require Options.dir['lib'] + 'rpc/server/framework'

module RPC
class Server

#
# Provides an RPC Instance to assist with general integration and UI development.
#
# It provides access to the {Options}, {Framework}, {Module::Manager},
# {Plugin::Manager} and {Spider} classes.
#
# It also provides very simple methods for:
# * {#scan Configuring and running a scan};
# * {#progress Aggregate progress information};
# * {#busy? Checking whether the scan is still in progress};
# * {#status Checking the status of the scan};
# * {#report Grabbing the report as a Hash};
# * {#report_as Grabbing the report in one of the supported formats};
# * {#shutdown Shutting down}.
#
# These methods are mapped to the 'service' RPC handler.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Instance
    include UI::Output
    include Utilities

    #
    # Initializes the RPC interface, the HTTP(S) server and the framework.
    #
    # @param    [Options]    opts
    #
    def initialize( opts, token )
        banner

        @opts  = opts
        @token = token
        @server = Base.new( @opts, token )

        @server.logger.level = @opts.datastore[:log_level] if @opts.datastore[:log_level]

        @opts.datastore[:token] = token

        debug if @opts.debug

        if @opts.reroute_to_logfile
            reroute_to_file "#{@opts.dir['logs']}/Instance - #{Process.pid}-#{@opts.rpc_port}.log"
        else
            reroute_to_file false
        end

        set_handlers

        # trap interrupts and exit cleanly when required
        %w(QUIT INT).each do |signal|
            trap( signal ){ shutdown } if Signal.list.has_key?( signal )
        end

        run
    end

    def busy?
        @scan_initializing ? true : @framework.busy?
    end

    # @see Framework#report
    def report
        @framework.report
    end

    # @see Framework#report_as
    def report_as( *args, &block )
        @framework.report_as( *args, &block )
    end

    # @see Framework#status
    def status
        @framework.status
    end

    # @see Framework#output
    def output( &block )
        @framework.output( &block )
    end

    #
    # Simplified version of {Framework#progress}.
    #
    # Returns the following information:
    # * +stats+ -- General runtime statistics (merged when part of Grid)
    # * +status+ -- {#status}
    # * +busy+ -- {#busy?}
    # * +issues+ -- {Framework#issues_as_hash} (disabled by default)
    # * +instances+ -- Raw +stats+ for each running instance (only when part of Grid) (disabled by default)
    #
    # @param    [Array<String,Array>,String,Symbol] options +:with_issues+, +:with_instances+
    #
    def progress( *options, &block )
        options = options.flatten.compact.map( &:to_sym )

        @framework.progress( as_hash: true, issues: options.include?( :with_issues ) ) do |data|
            data.delete( 'messages' )

            if @framework.solo? || !options.include?( :with_instances )
                data.delete( 'instances' )
            end

            data['instances'] ||= [] if options.include?( :with_instances )

            block.call( data )
        end
    end

    #
    # Configures and runs s scan.
    #
    # If you use this method to start the scan use {#busy?} instead of
    # {Framework#busy?} to check if the scan is still running.
    #
    # @param    [Hash]  opts    scan options to be passed to {Options#set}
    #   Supports the following extra options:
    #   * +slaves+ -- +Array<Hash>+, each item will be passed to {Framework#enslave}.
    #   * +spawns+ -- +Integer+, the amount of slaves to spawn.
    #   * +pages+ -- +Array<{Page}>+, extra pages to audit.
    #   * +elements+ -- +Array<{String}>+, elements to which to restrict the audit
    #       (using elements IDs as returned by {Element::Capabilities::Auditable#scope_audit_id}).
    #
    def scan( opts = {}, &block )
        # if the instance isn't clean bail out now
        if @scan_initializing || @framework.busy?
            block.call false
            return false
        end

        @scan_initializing = true
        opts = opts.to_hash.inject( {} ) { |h, (k, v)| h[k.to_sym] = v; h }

        if opts[:plugins] && opts[:plugins].is_a?( Array )
            opts[:plugins] = opts[:plugins].inject( {} ) { |h, n| h[n] = {}; h }
        end

        @framework.opts.set( opts )

        @framework.update_page_queue( opts[:pages] || [] )
        @framework.restrict_to_elements( opts[:elements] || [] )

        opts[:modules] ||= opts[:mods]
        @framework.modules.load opts[:modules] if opts[:modules]
        @framework.plugins.load opts[:plugins] if opts[:plugins]

        each  = proc { |slave, iter| @framework.enslave( slave ){ iter.next } }
        after = proc { block.call @framework.run; @scan_initializing = false }

        slaves  = opts[:slaves] || []

        spawn( opts[:spawns].to_i ) do |spawns|
            slaves |= spawns
            ::EM::Iterator.new( slaves, slaves.empty? ? 1 : slaves.size ).
                each( each, after )
        end

        true
    end

    #
    # Makes the server go bye-bye...Lights out!
    #
    def shutdown
        print_status 'Shutting down...'

        t = []
        @framework.instance_eval do
            @instances.each do |instance|
                # Don't know why but this works better than EM's stuff
                t << Thread.new { connect_to_instance( instance ).service.shutdown! }
            end
        end
        t.join

        @server.shutdown
        true
    end
    alias :shutdown! :shutdown

    def alive?
        @server.alive?
    end

    private

    def spawn( num, &block )
        if num == 0
            block.call []
            return
        end

        q = ::EM::Queue.new

        if has_dispatcher?
            num.times do
                dispatcher.dispatch( @framework.self_url ) do |instance|
                    q << instance
                end
            end
        else
            num.times do
                port  = available_port
                token = generate_token

                Process.detach ::EM.fork_reactor {
                    # make sure we start with a clean env (namepsace, opts, etc)
                    Framework.reset

                    Options.rpc_port = port
                    Server::Instance.new( Options.instance, token )
                }

                instance_info = { 'url' => "#{Options.rpc_address}:#{port}",
                                  'token' => token }

                wait_till_alive( instance_info ) { q << instance_info }
            end
        end

        spawns = []
        num.times do
            q.pop do |r|
                spawns << r
                block.call( spawns ) if spawns.size == num
            end
        end
    end

    def wait_till_alive( instance_info, &block )
        opts = ::OpenStruct.new

        # if after 100 retries we still haven't managed to get through give up
        opts.max_retries = 100
        opts.ssl_ca      = @opts.ssl_ca,
        opts.ssl_pkey    = @opts.node_ssl_pkey || @opts.ssl_pkey,
        opts.ssl_cert    = @opts.node_ssl_cert || @opts.ssl_cert

        Client::Instance.new(
            opts, instance_info['url'], instance_info['token']
        ).service.alive? do |alive|
            if alive.rpc_exception?
                raise alive
            else
                block.call alive
            end
        end
    end

    #
    # Starts the HTTPS server and the RPC service.
    #
    def run
        print_status 'Starting the server...'
        @server.run
    end

    def dispatcher
        @dispatcher ||=
            Client::Dispatcher.new( @opts, @opts.datastore[:dispatcher_url] )
    end

    def has_dispatcher?
        !!@opts.datastore[:dispatcher_url]
    end

    #
    # Outputs the Arachni banner.
    #
    # Displays version number, revision number, author details etc.
    #
    def banner
        puts BANNER
        puts
        puts
    end

    # Prepares all the RPC handlers.
    def set_handlers
        @server.add_async_check do |method|
            # methods that expect a block are async
            method.parameters.flatten.include?( :block )
        end

        @framework = Server::Framework.new( Options.instance )

        @server.add_handler( 'service',   self )
        @server.add_handler( 'framework', @framework )
        @server.add_handler( 'opts',      @framework.opts )
        @server.add_handler( 'spider',    @framework.spider )
        @server.add_handler( 'modules',   @framework.modules )
        @server.add_handler( 'plugins',   @framework.plugins )
    end

end

end
end
end
