=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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
lib = Options.dir['lib']

require lib + 'rpc/client/instance'
require lib + 'rpc/client/dispatcher'

require lib + 'rpc/server/base'
require lib + 'rpc/server/active_options'
require lib + 'rpc/server/output'
require lib + 'rpc/server/framework'

module RPC
class Server

#
# Represents a single Arachni instance and serves as a central point of access
# to a scanner's components:
# * {Instance} -- mapped to +service+
# * {Options} -- mapped to +opts+
# * {Framework} -- mapped to +framework+
# * {Module::Manager} -- mapped to +modules+
# * {Plugin::Manager} -- mapped to +plugins+
# * {Spider} -- mapped to +spider+
#
# It also provides convenience methods for:
# * {#scan Configuring and running a scan};
# * {#progress Aggregate progress information};
# * {#busy? Checking whether the scan is still in progress};
# * {#status Checking the status of the scan};
# * {#report Grabbing the report as a Hash};
# * {#report_as Grabbing the report in one of the supported formats};
# * {#shutdown Shutting down}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Instance
    include UI::Output
    include Utilities

    private :error_logfile
    public  :error_logfile

    #
    # Initializes the RPC interface and the framework.
    #
    # @param    [Options]    opts
    # @param    [String]    token   Authentication token.
    #
    def initialize( opts, token )
        banner

        @opts   = opts
        @token  = token

        @server = Base.new( @opts, token )

        @server.logger.level = @opts.datastore[:log_level] if @opts.datastore[:log_level]

        @opts.datastore[:token] = token

        debug if @opts.debug

        if @opts.reroute_to_logfile
            reroute_to_file "#{@opts.dir['logs']}/Instance - #{Process.pid}-#{@opts.rpc_port}.log"
        else
            reroute_to_file false
        end

        set_error_logfile "#{@opts.dir['logs']}/Instance - #{Process.pid}-#{@opts.rpc_port}.error.log"

        set_handlers

        # trap interrupts and exit cleanly when required
        %w(QUIT INT).each do |signal|
            trap( signal ){ shutdown } if Signal.list.has_key?( signal )
        end

        run
    end

    # @return   [true]
    def alive?
        @server.alive?
    end

    # @return   [Bool]
    #   +true+ if the scan is initializing or running, +false+ otherwise.
    #   If a scan is started by {#scan} then this method should be used
    #   instead of {Framework#busy?}.
    def busy?
        @scan_initializing ? true : @framework.busy?
    end

    # @see Framework#errors
    def errors( starting_line = 0, &block )
        @framework.errors( starting_line, &block )
    end

    # @see Framework#pause
    def pause( &block )
        @framework.pause( &block )
    end

    # @see Framework#resume
    def resume( &block )
        @framework.resume( &block )
    end

    #
    # Cleans up and returns the report.
    #
    # @param   [Symbol] report_type
    #   Report type to return, +:hash+ for {#report} or +:audistore+ for {#auditstore}.
    #
    def abort_and_report( report_type = :hash, &block )
        @framework.clean_up do
            block.call report_type == :auditstore ? auditstore : report
        end
    end

    #
    # Cleans up and delegates to {#report_as}.
    #
    # @see #report_as
    #
    def abort_and_report_as( *args, &block )
        @framework.clean_up do
            block.call report_as( *args )
        end
    end

    # @see Framework#auditstore
    def auditstore
        @framework.auditstore
    end

    # @see Framework#report
    def report
        @framework.report
    end

    # @see Framework#report_as
    def report_as( *args )
        @framework.report_as( *args )
    end

    # @see Framework#status
    def status
        @framework.status
    end

    # @see Framework#output
    # @deprecated
    def output( &block )
        @framework.output( &block )
    end

    #
    # Simplified version of {Framework#progress}.
    #
    # Returns the following information:
    # * +stats+ -- General runtime statistics (merged when part of Grid) (enabled by default)
    # * +status+ -- {#status}
    # * +busy+ -- {#busy?}
    # * +issues+ -- {Framework#issues_as_hash} (disabled by default)
    # * +instances+ -- Raw +stats+ for each running instance (only when part of Grid) (disabled by default)
    # * +errors+ -- {#errors} (disabled by default)
    #
    # @param    [Hash] options +{ with: [ :issues, :instances ], without: :stats }+
    #
    def progress( options = {}, &block )
        with    = parse_progress_opts( options, :with )
        without = parse_progress_opts( options, :without )

        @framework.progress( as_hash:   !with.include?( :native_issues ),
                             issues:    with.include?( :native_issues ) || with.include?( :issues ),
                             stats:     !without.include?( :stats ),
                             slaves:    with.include?( :instances ),
                             messages:  false,
                             errors:    with[:errors]
        ) do |data|
            data['instances'] ||= [] if with.include?( :instances )
            data['busy'] = busy?

            if data['issues']
                data['issues'] = data['issues'].dup

                if without[:issues].is_a? Array
                    data['issues'].reject! do |i|
                        without[:issues].include?( i.is_a?( Hash ) ? i['digest'] : i.digest )
                    end
                end
            end

            block.call( data )
        end
    end

    #
    # Configures and runs s scan.
    #
    # If you use this method to start the scan use {#busy?} instead of
    # {Framework#busy?} to check if the scan is still running.
    #
    # @param    [Hash]  opts
    #   Scan options to be passed to {Options#set}. Supports the following
    #   extra options:
    # @option opts [Array<Hash>]  :slaves  Each item will be passed to {Framework#enslave}.
    # @option opts [Integer]  :spawns The amount of slaves to spawn.
    # @option opts [Array<Page>]  :pages Extra pages to audit.
    # @option opts [Array<String>]  :elements
    #   Elements to which to restrict the audit (using elements IDs as returned
    #   by {Element::Capabilities::Auditable#scope_audit_id}).
    #
    def scan( opts = {}, &block )
        # if the instance isn't clean bail out now
        if @scan_initializing || @framework.busy?
            block.call false
            return false
        end

        opts = opts.to_hash.inject( {} ) { |h, (k, v)| h[k.to_sym] = v; h }
        slaves  = opts[:slaves] || []
        spawn_count = opts[:spawns].to_i

        if opts[:plugins] && opts[:plugins].is_a?( Array )
            opts[:plugins] = opts[:plugins].inject( {} ) { |h, n| h[n] = {}; h }
        end

        if opts[:grid] && spawn_count <= 0
            fail ArgumentError,
                 'Spawn count (:spawns) must be more than 1 for Grid scans.'
        end

        if (opts[:grid] || spawn_count > 0) &&
            [opts[:restrict_paths]].flatten.compact.any?
            fail ArgumentError,
                 'Option \'restrict_paths\' is not supported when in High-Performance mode.'
        end

        @scan_initializing = true
        @framework.opts.set( opts )

        @framework.update_page_queue( opts[:pages] || [] )
        @framework.restrict_to_elements( opts[:elements] || [] )

        opts[:modules] ||= opts[:mods]
        @framework.modules.load opts[:modules] if opts[:modules]
        @framework.plugins.load opts[:plugins] if opts[:plugins]

        each  = proc { |slave, iter| @framework.enslave( slave ){ iter.next } }
        after = proc { block.call @framework.run; @scan_initializing = false }

        # If the Dispatchers are in a Grid config but the user has not requested
        # a Grid scan force the framework to ignore the Grid and work with
        # the instances we give it.
        @framework.ignore_grid if has_dispatcher? && !opts[:grid]

        # If a Grid scan has been selected then just set us as the master
        # and set the spawn count as max slaves.
        if opts[:grid]
            @framework.set_as_master
            @framework.opts.max_slaves = spawn_count
            after.call
        else
            spawn( spawn_count ) do |spawns|
                slaves |= spawns
                ::EM::Iterator.new( slaves, slaves.empty? ? 1 : slaves.size ).
                    each( each, after )
            end
        end

        true
    end

    # Makes the server go bye-bye...Lights out!
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

    # @private
    def error_test( str )
        print_error str.to_s
    end

    private

    def parse_progress_opts( options, key )
        parsed = {}
        [options.delete( key ) || options.delete( key.to_s )].each do |w|
            next if !w

            case w
                when Array
                    w.compact.flatten.each do |q|
                        case q
                            when String, Symbol
                                parsed[q.to_sym] = nil
                            when Hash
                                parsed.merge!( q )
                        end
                    end

                when String, Symbol
                    parsed[w.to_sym] = nil

                when Hash
                    parsed.merge!( w )
            end
        end

        parsed
    end

    def spawn( num, &block )
        if num <= 0
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
        @server.add_handler( "opts",      Server::ActiveOptions.new( @framework ) )
        @server.add_handler( 'spider',    @framework.spider )
        @server.add_handler( 'modules',   @framework.modules )
        @server.add_handler( 'plugins',   @framework.plugins )
    end

end

end
end
end
