=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
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
# Represents an Arachni instance (or multiple instances when running a
# high-performance scan) and serves as a central point of access to the
# scanner's components:
#
# * {Instance self} -- mapped to `service`
# * {Options} -- mapped to `opts`
# * {Framework} -- mapped to `framework`
# * {Check::Manager} -- mapped to `checks`
# * {Plugin::Manager} -- mapped to `plugins`
# * {Spider} -- mapped to `spider`
#
# # Convenience methods
#
# The `service` RPC handler (which is this class) provides convenience
# methods which cover the most commonly used functionality so that you
# won't have to concern yourself with any other RPC handler.
#
# This should be the only RPC API you'll ever need.
#
# Provided methods for:
#
# * Retrieving available components
#   * {#list_checks Checks}
#   * {#list_plugins Plugins}
#   * {#list_reports Reports}
# * {#scan Configuring and running a scan}
# * Retrieving progress information
#   * {#progress in aggregate form} (which includes a multitude of information)
#   * or simply by:
#       * {#busy? checking whether the scan is still in progress}
#       * {#status checking the status of the scan}
# * {#pause Pausing}, {#resume resuming} or {#abort_and_report aborting} the scan.
# * Retrieving the scan report
#   * {#report as a Hash} or a native {#auditstore AuditStore} object
#   * {#report_as in one of the supported formats} (as made available by the
#     {Reports report} components)
# * {#shutdown Shutting down}
#
# (A nice simple example can be found in the {UI::CLI::RPC RPC command-line client}
# interface.)
#
# @example A minimalistic example -- assumes Arachni is installed and available.
#    require 'arachni'
#    require 'arachni/rpc/client'
#
#    instance = Arachni::RPC::Client::Instance.new( Arachni::Options.instance,
#                                                   'localhost:1111', 's3cr3t' )
#
#    instance.service.scan url: 'http://testfire.net',
#                          audit_links: true,
#                          audit_forms: true,
#                          # load all XSS checks
#                          checks: 'xss*'
#
#    print 'Running.'
#    while instance.service.busy?
#        print '.'
#        sleep 1
#    end
#
#    # Grab the report as a native AuditStore object
#    report = instance.service.auditstore
#
#    # Kill the instance and its process, no zombies please...
#    instance.service.shutdown
#
#    puts
#    puts
#    puts 'Logged issues:'
#    report.issues.each do |issue|
#        puts "  * #{issue.name} for input '#{issue.var}' at '#{issue.url}'."
#    end
#
# @note Ignore:
#
#   * Inherited methods and attributes -- only public methods of this class are
#       accessible over RPC.
#   * `block` parameters, they are an RPC implementation detail for methods which
#       perform asynchronous operations.
#
# @note Avoid calling methods which return Arachni-specific objects (like {AuditStore},
#   {Issue}, etc.) when you don't have these objects available on the client-side
#   (like when working from a non-Ruby platform or not having the Arachni framework
#   installed).
#
# @note Methods which expect `Symbol` type parameters will also accept `String`
#   types as well.
#
#   For example, the following:
#
#       instance.service.scan url: 'http://testfire.net'
#
#   Is the same as:
#
#       instance.service.scan 'url' => 'http://testfire.net'
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
        @opts   = opts
        @token  = token

        @framework      = Server::Framework.new( Options.instance )
        @active_options = Server::ActiveOptions.new( @framework )

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

        set_handlers( @server )

        # trap interrupts and exit cleanly when required
        %w(QUIT INT).each do |signal|
            trap( signal ){ shutdown if !@opts.datastore[:do_not_trap] } if Signal.list.has_key?( signal )
        end

        @consumed_pids = []

        ::EM.run do
            run
        end
    end

    # @return   [true]
    def alive?
        @server.alive?
    end

    # @return   [Bool]
    #   `true` if the scan is initializing or running, `false` otherwise.
    #   If a scan is started by {#scan} then this method should be used
    #   instead of {Framework#busy?}.
    def busy?( &block )
        if @scan_initializing
            block.call( true ) if block_given?
            return true
        end

        @framework.busy?( &block )
    end

    # @param (see Arachni::RPC::Server::Framework#errors)
    # @return (see Arachni::RPC::Server::Framework#errors)
    def errors( starting_line = 0, &block )
        @framework.errors( starting_line, &block )
    end

    # @return (see Arachni::Framework#list_platforms)
    def list_platforms
        @framework.list_platforms
    end

    # @return (see Arachni::Framework#list_checks)
    def list_checks
        @framework.list_checks
    end

    # @return (see Arachni::Framework#list_plugins)
    def list_plugins
        @framework.list_plugins
    end

    # @return (see Arachni::Framework#list_reports)
    def list_reports
        @framework.list_reports
    end

    #
    # Pauses the running scan on a best effort basis.
    #
    # @see Framework#pause
    def pause( &block )
        @framework.pause( &block )
    end

    #
    # Resumes a paused scan.
    #
    # @see Framework#resume
    def resume( &block )
        @framework.resume( &block )
    end

    #
    # Cleans up and returns the report.
    #
    # @param   [Symbol] report_type
    #   Report type to return, `:hash` for {#report} or `:audistore` for
    #   {#auditstore}.
    #
    # @return  [Hash,AuditStore]
    #
    # @note Don't forget to {#shutdown} the instance once you get the report.
    #
    # @see Framework#clean_up
    # @see #abort_and_report
    # @see #report
    # @see #auditstore
    #
    def abort_and_report( report_type = :hash, &block )
        @framework.clean_up do
            block.call report_type.to_sym == :auditstore ? auditstore : report
        end
    end

    #
    # Cleans up and delegates to {#report_as}.
    #
    # @param (see #report_as)
    # @return (see #report_as)
    #
    # @note Don't forget to {#shutdown} the instance once you get the report.
    #
    # @see Framework#clean_up
    # @see #abort_and_report
    # @see #report_as
    #
    def abort_and_report_as( name, &block )
        @framework.clean_up do
            block.call report_as( name )
        end
    end

    # @return (see Arachni::Framework#auditstore)
    # @see Framework#auditstore
    def auditstore
        @framework.auditstore
    end

    # @return (see Arachni::RPC::Server::Framework#report)
    # @see Framework#report
    def report
        @framework.report
    end

    # @param    [String]    name
    #   Name of the report component to run, as presented by {#list_reports}'s
    #   `:shortname` key.
    #
    # @return (see Arachni::Framework#report_as)
    # @see Framework#report_as
    def report_as( name )
        @framework.report_as( name )
    end

    # @return (see Framework#status)
    # @see Framework#status
    def status
        @framework.status
    end

    #
    # Simplified version of {Framework::MultiInstance#progress}.
    #
    # # Recommended usage
    #
    #   Please request from the method only the things you are going to actually
    #   use, otherwise you'll just be wasting bandwidth.
    #   In addition, ask to **not** be served data you already have, like issues
    #   or error messages.
    #
    #   To be kept completely up to date on the progress of a scan (i.e. receive
    #   new issues and error messages asap) in an efficient manner, you will need
    #   to keep track of the issues and error messages you already have and
    #   explicitly tell the method to not send the same data back to you on
    #   subsequent calls.
    #
    # ## Retrieving errors (`:errors` option) without duplicate data
    #
    #   This is done by telling the method how many error messages you already
    #   have and you will be served the errors from the error-log that are past
    #   that line.
    #   So, if you were to use a loop to get fresh progress data it would look
    #   like so:
    #
    #     error_cnt = 0
    #     i = 0
    #     while sleep 1
    #         # Test method, triggers an error log...
    #         instance.service.error_test "BOOM! #{i+=1}"
    #
    #         # Only request errors we don't already have
    #         errors = instance.service.progress( with: { errors: error_cnt } )['errors']
    #         error_cnt += errors.size
    #
    #         # You will only see new errors
    #         puts errors.join("\n")
    #     end
    #
    # ## Retrieving issues without duplicate data
    #
    #   In order to be served only new issues you will need to let the method
    #   know which issues you already have. This is done by providing a list
    #   of {Issue#digest digests} for the issues you already know about.
    #
    #     issue_digests = []
    #     while sleep 1
    #         issues = instance.service.progress(
    #                      # Ask for native Arachni::Issue object instead of hashes
    #                      with: :native_issues,
    #                      # Only request issues we don't already have
    #                      without: { issues: issue_digests  }
    #                  )['issues']
    #
    #         issue_digests |= issues.map( &:digest )
    #
    #         # You will only see new issues
    #         issues.each do |issue|
    #             puts "  * #{issue.name} for input '#{issue.var}' at '#{issue.url}'."
    #         end
    #     end
    #
    #   _If your client is on a platform that has no access to native Arachni
    #   objects, you'll have to calculate the {Issue#digest digests} yourself._
    #
    # @param  [Hash]  options
    #   Options about what progress data to retrieve and return.
    # @option options [Array<Symbol, Hash>]  :with
    #   Specify data to include:
    #
    #   * :native_issues -- Discovered issues as {Arachni::Issue} objects.
    #   * :issues -- Discovered issues as {Arachni::Issue#to_h hashes}.
    #   * :instances -- Statistics and info for slave instances.
    #   * :errors -- Errors and the line offset to use for {#errors}.
    #     Pass as a hash, like: `{ errors: 10 }`
    # @option options [Array<Symbol, Hash>]  :without
    #   Specify data to exclude:
    #
    #   * :stats -- Don't include runtime statistics.
    #   * :issues -- Don't include issues with the given {Arachni::Issue#digest digests}.
    #     Pass as a hash, like: `{ issues: [...] }`
    #
    # @return [Hash]
    #   * `stats` -- General runtime statistics (merged when part of Grid)
    #       (enabled by default)
    #   * `status` -- {#status}
    #   * `busy` -- {#busy?}
    #   * `issues` -- {Framework#issues_as_hash} or {Framework#issues}
    #       (disabled by default)
    #   * `instances` -- Raw `stats` for each running instance (only when part
    #       of Grid) (disabled by default)
    #   * `errors` -- {#errors} (disabled by default)
    #
    def progress( options = {}, &block )
        with    = parse_progress_opts( options, :with )
        without = parse_progress_opts( options, :without )

        @framework.progress( as_hash:   !with.include?( :native_issues ),
                             issues:    with.include?( :native_issues ) ||
                                            with.include?( :issues ),
                             stats:     !without.include?( :stats ),
                             slaves:    with.include?( :instances ),
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
    # Configures and runs a scan.
    #
    # @note If you use this method to start the scan use {#busy?} instead of
    #   {Framework#busy?} to check if the scan is still running.
    #
    # @note Options marked with an asterisk are required.
    # @note Options which expect patterns will interpret their arguments as
    #   regular expressions regardless of their type.
    # @note When using more than one Instance, the `http_req_limit` and
    #   `link_count_limit` options will be divided by the number of Instance to
    #   be used.
    #
    # @param  [Hash]  opts
    #   Scan options to be passed to {Options#set} (along with some extra ones
    #   to keep configuration in one place).
    #
    #   _The options presented here are the most commonly used ones, in
    #   actuality, you can use any {Options} attribute._
    # @option opts [String]  *:url
    #   Target URL to audit.
    # @option opts [Boolean] :audit_links (false)
    #   Enable auditing of link inputs.
    # @option opts [Boolean] :audit_forms (false)
    #   Enable auditing of form inputs.
    # @option opts [Boolean] :audit_cookies (false)
    #   Enable auditing of cookie inputs.
    # @option opts [Boolean] :audit_headers (false)
    #   Enable auditing of header inputs.
    # @option opts [String,Array<String>] :checks ([])
    #   Checks to load, by name.
    #
    #       # To load all checks use the wildcard on its own
    #       '*'
    #
    #       # To load all XSS and SQLi checks:
    #       [ 'xss*', 'sqli*' ]
    #
    # @option opts [Hash<Hash>] :plugins ({})
    #   Plugins to load, by name, along with their options.
    #
    #       {
    #           'proxy'      => {}, # empty options
    #           'autologin'  => {
    #               'url'    => 'http://demo.testfire.net/bank/login.aspx',
    #               'params' => 'uid=jsmith&passw=Demo1234',
    #               'check'  => 'MY ACCOUNT'
    #           },
    #       }
    #
    # @option opts [String, Symbol, Array<String, Symbol>] :platforms ([])
    #   Initialize the fingerprinter with the given platforms. The fingerprinter
    #   cannot identify database servers so specifying the remote DB backend will
    #   greatly enhance performance and reduce bandwidth consumption.
    # @option opts [Integer] :no_fingerprinting (false)
    #   Disable platform fingerprinting and include all payloads in the audit.
    #   Use this option in addition to the `:platforms` one to restrict the
    #   audit payloads to explicitly specified platforms.
    # @option opts [Integer] :link_count_limit (nil)
    #   Limit the amount of pages to be crawled and audited.
    # @option opts [Integer] :depth_limit (nil)
    #   Directory depth limit.
    #
    #   How deep Arachni should go into the website structure.
    # @option opts [Array<String, Regexp>] :exclude ([])
    #   URLs that match any of the given patterns will be ignored.
    #
    #       [ 'logout', /skip.*.me too/i ]
    #
    # @option opts [Array<String, Regexp>] :exclude_pages ([])
    #   Exclude pages from the crawl and audit processes based on their
    #   content (i.e. HTTP response bodies).
    #
    #       [ /.*forbidden.*/, "I'm a weird 404 and I should be ignored" ]
    #
    # @option opts [Array<String>] :exclude_vectors ([])
    #   Exclude input vectors from the audit, by name.
    #
    #       [ 'sessionid', 'please_dont_audit_me' ]
    #
    # @option opts [Array<String, Regexp>] :include ([])
    #   Only URLs that match any of the given patterns will be followed and audited.
    #
    #       [ 'only-follow-me', 'follow-me-as-well' ]
    #
    # @option opts [Hash<<String, Regexp>,Integer>] :redundant ({})
    #   Redundancy patterns to limit how many times certain paths should be
    #   followed.
    #
    #       { "follow_me_3_times" => 3, /follow_me_5_times/ => 5 }
    #
    #   Useful when scanning pages that create an large number of
    #   pages like galleries and calendars.
    #
    # @option opts [Array<String>] :restrict_paths ([])
    #   Restrict the audit to the provided paths.
    #
    #   The crawl phase gets skipped and these paths are used instead.
    # @option opts [Array<String>] :extend_paths ([])
    #   Extend the scope of the crawl and audit with the provided paths.
    # @option opts [Array<String, Hash, Arachni::Element::Cookie>] :cookies ({})
    #   Cookies to use for the HTTP requests.
    #
    #       [
    #           'secret=blah',
    #           {
    #               'userid' => '1',
    #           },
    #           {
    #               name:      'sessionid',
    #               value:     'fdfdfDDfsdfszdf',
    #               http_only: true
    #           }
    #       ]
    #
    #   _Cookie values will be encoded automatically._
    #
    # @option opts [Integer] :http_req_limit (20)
    #   HTTP request concurrency limit.
    # @option opts [String] :user_agent ('Arachni/v<version>')
    #   User agent to use.
    # @option opts [String] :authed_by (nil)
    #   The e-mail address of the person who authorized the scan.
    #
    #       john.doe@bigscanners.com
    #
    # @option opts [Array<Hash>]  :slaves
    #   Info of Instances to {Framework::Master#enslave enslave}.
    #
    #       [
    #           { url: 'address:port', token: 's3cr3t' },
    #           { url: 'anotheraddress:port', token: '3v3nm0r3s3cr3t' }
    #       ]
    #
    # @option opts [Bool]  :grid    (false)
    #   Uses the Dispatcher Grid to obtain slave instances for a multi-Instance
    #   scan.
    #
    #   If set to `true`, it serves as a shorthand for:
    #
    #       grid_mode: :balance
    #
    # @option opts [String, Symbol]  :grid_mode    (nil)
    #   Grid mode to use, available modes are:
    #
    #   * `nil` -- No grid.
    #   * `:balance` -- Slave Instances will be provided by the least burdened
    #       grid members to keep the overall Grid workload even across all Dispatchers.
    #   * `:aggregate` -- Same as `:balance` but with high-level line-aggregation.
    #       Will only request Instances from Grid members with different Pipe-IDs.
    # @option opts [Integer]  :spawns   (0)
    #   The amount of slaves to spawn. The behavior of this option changes
    #   depending on the `grid_mode` setting:
    #
    #   * `nil` -- All slave Instances will be spawned by this Instance directly,
    #       and thus reside in the same machine. This has the added benefit of
    #       using UNIX-domain sockets for inter-process communication and avoiding
    #       the overhead of TCP/IP.
    #   * `:balance` -- Slaves will be provided by the least burdened Grid Dispatchers.
    #   * `:aggregate` -- Slaves will be provided by Grid Dispatchers with unique
    #       Pipe-IDs and the value of this option will be treated as a possible
    #       maximum rather than a hard setting. Actual spawn count will be determined
    #       by Dispatcher availability and the size of the workload.
    #
    def scan( opts = {}, &block )
        # If the instance isn't clean bail out now.
        if busy? || @called
            block.call false
            return false
        end

        # Normalize this sucker to have symbols as keys -- but not recursively.
        opts = opts.symbolize_keys( false )

        slaves      = opts[:slaves] || []
        spawn_count = opts[:spawns].to_i

        if opts[:platforms]
            begin
                Platform::Manager.new( [opts[:platforms]].flatten.compact )
            rescue => e
                fail ArgumentError, e.to_s
            end
        end

        if opts[:grid_mode]
            @framework.opts.grid_mode = opts[:grid_mode]
        end

        if (opts[:grid] || opts[:grid_mode]) && spawn_count <= 0
            fail ArgumentError,
                 'Option \'spawns\' must be greater than 1 for Grid scans.'
        end

        if ((opts[:grid] || opts[:grid_mode]) || spawn_count > 0) && [opts[:restrict_paths]].flatten.compact.any?
            fail ArgumentError,
                 'Option \'restrict_paths\' is not supported when in multi-Instance mode.'
        end

        # There may be follow-up/retry calls by the client in cases of network
        # errors (after the request has reached us) so we need to keep minimal
        # track of state in order to bail out on subsequent calls.
        @called = @scan_initializing = true

        # Plugins option needs to be a hash...
        if opts[:plugins] && opts[:plugins].is_a?( Array )
            opts[:plugins] = opts[:plugins].inject( {} ) { |h, n| h[n] = {}; h }
        end

        @active_options.set( opts )

        if @framework.opts.url.to_s.empty?
            fail ArgumentError, 'Option \'url\' is mandatory.'
        end

        # Undocumented option, used internally to distribute workload and knowledge
        # for multi-Instance scans.
        if opts[:multi]
            @framework.update_page_queue( opts[:multi][:pages] || [] )
            @framework.restrict_to_elements( opts[:multi][:elements] || [] )

            if Options.fingerprint?
                Platform::Manager.update_light( opts[:multi][:platforms] || {} )
            end
        end

        opts[:checks] ||= opts[:mods]
        @framework.checks.load opts[:checks] if opts[:checks]
        @framework.plugins.load opts[:plugins] if opts[:plugins]

        # Starts the scan after all necessary options have been set.
        after = proc { block.call @framework.run; @scan_initializing = false }

        if @framework.opts.grid?
            # If a Grid scan has been selected then just set us as the master
            # and set the spawn count as max slaves.
            #
            # The Framework will sort out the rest...
            @framework.set_as_master
            @framework.opts.max_slaves = spawn_count

            # Rock n' roll!
            after.call
        else
            # Handles each spawn, enslaving it for a multi-Instance scan.
            each  = proc do |slave, iter|
                @framework.enslave( slave ){ iter.next }
            end

            spawn( spawn_count ) do |spawns|
                # Add our spawns to the slaves list which was passed as an option.
                slaves |= spawns

                # Process the Instances.
                ::EM::Iterator.new( slaves, slaves.empty? ? 1 : slaves.size ).
                    each( each, after )
            end
        end

        true
    end

    # Makes the server go bye-bye...Lights out!
    def shutdown( &block )
        print_status 'Shutting down...'

        ::EM.defer do
            t = []
            @framework.instance_eval do
                next if !has_slaves?
                @instances.each do |instance|
                    # Don't know why but this works better than EM's stuff
                    t << Thread.new { connect_to_instance( instance ).service.shutdown }
                end
            end
            t.join

            @server.shutdown

            block.call true if block_given?
        end

        true
    end

    # @private
    def error_test( str, &block )
        @framework.error_test( str, &block )
    end

    def consumed_pids
        @consumed_pids | [Process.pid]
    end

    private

    def parse_progress_opts( options, key )
        parsed = {}
        [options.delete( key ) || options.delete( key.to_s )].compact.each do |w|
            case w
                when Array
                    w.compact.flatten.each do |q|
                        case q
                            when String, Symbol
                                parsed[q.to_sym] = nil
                            when Hash
                                parsed.merge!( q.symbolize_keys )
                        end
                    end

                when String, Symbol
                    parsed[w.to_sym] = nil

                when Hash
                    parsed.merge!( w.symbolize_keys )
            end
        end

        parsed
    end

    #
    # Provides `num` Instances.
    #
    # New Instance processes will be spawned and immediately detached.
    # Spawns will listen on a UNIX socket and the master will expose itself
    # over a UNIX socket as well so that IPC won't have to go over TCP/IP.
    #
    # @param    [Integer]   num Amount of Instances to return.
    #
    # @return   [Array<Hash>]   Instance info (urls and tokens).
    #
    def spawn( num, &block )
        if num <= 0
            block.call []
            return
        end

        q = ::EM::Queue.new

        # Before spawning slaves, expose our API over a UNIX socket via
        # which they should talk to us.
        expose_over_unix_socket do
            num.times do
                token = generate_token

                pid = fork {
                    # Make sure we start with a clean env (namepsace, opts, etc).
                    @framework.reset

                    # All Instances will be on the same host so use UNIX
                    # domain sockets to avoid TCP/IP overhead.
                    Options.rpc_address          = nil
                    Options.rpc_external_address = nil
                    Options.rpc_port             = nil
                    Options.rpc_socket           = "/tmp/arachni-instance-slave-#{Process.pid}"

                    Server::Instance.new( Options.instance, token )
                }

                Process.detach pid
                @consumed_pids << pid

                instance_info = { 'url' => "/tmp/arachni-instance-slave-#{pid}",
                                  'token' => token }

                wait_till_alive( instance_info['url'] ) { q << instance_info }
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

    def wait_till_alive( socket, &block )
        ::EM.defer do
            # We're using UNIX sockets as URLs so wait till the Instance
            # has created its socket before proceeding.
            sleep 0.1 while !File.exist?( socket )
            block.call true
        end
    end

    # Starts  RPC service.
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

    # Outputs the Arachni banner.
    #
    # Displays version number, author details etc.
    def banner
        puts BANNER
        puts
        puts
    end

    # Exposes self over an UNIX socket.
    #
    # @param    [Block] block
    #   Block to call once the operation has completed.
    def expose_over_unix_socket( &block )
        # If it's already exposed over a UNIX socket then there's nothing to
        # be done.
        if Options.rpc_socket
            block.call true
            return
        end

        Options.rpc_socket = "/tmp/arachni-instance-master-#{Process.pid}"

        ::EM.defer do
            unix = Base.new( @opts, @token )
            set_handlers( unix )

            ::EM.defer do
                unix.run
            end

            sleep 0.1 while !File.exist?( Options.rpc_socket )
            block.call true
        end

        true
    end

    # @param    [Base]  server
    #   Prepares all the RPC handlers for the given `server`.
    def set_handlers( server )
        server.add_async_check do |method|
            # methods that expect a block are async
            method.parameters.flatten.include? :block
        end

        server.add_handler( 'service',   self )
        server.add_handler( 'framework', @framework )
        server.add_handler( 'opts',      @active_options )
        server.add_handler( 'spider',    @framework.spider )
        server.add_handler( 'checks',    @framework.checks )
        server.add_handler( 'plugins',   @framework.plugins )
    end

end

end
end
end
